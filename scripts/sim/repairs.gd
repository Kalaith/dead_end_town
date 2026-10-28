extends RefCounted
## Bounded prepaid repair capacity. No credit survives a completed batch.
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const IDS: Array[String] = ["repair_line", "gate_rebuild", "legacy_repair"]


static func describe(catalog: Dictionary, target: String) -> Dictionary:
	var parts: PackedStringArray = target.split(":")
	if parts.size() != 2:
		return {}
	var group: String = parts[0]
	var id: String = parts[1]
	var entries: Array = catalog.properties if group == "gate" else (catalog.passages if group == "passage" else catalog.barricades if group == "road" else [])
	for d: Dictionary in entries:
		if d.id != id:
			continue
		var points: Array = [d.gate] if group == "gate" else (d.sites if group == "passage" else [d.site])
		var player_point: Vector2 = Routes.point(d.center) if group == "road" else Routes.point(points[0])
		return {"group": group, "id": id, "name": d.name, "points": points, "player_point": player_point, "range": 76.0 if group == "gate" else float(catalog.balance.passage_range if group == "passage" else catalog.balance.barricade_work_range), "requires": [id] if group == "gate" else d.requires, "max": float(catalog.balance.barricade_health if group == "road" else catalog.balance.gate_health)}
	return {}


static func state(world: RefCounted, d: Dictionary) -> Dictionary:
	return world.properties[d.id] if d.group == "gate" else (world.passages[d.id] if d.group == "passage" else world.roadworks[d.id])


static func health(s: Dictionary, d: Dictionary) -> float:
	return float(s.gate_hp if d.group == "gate" else s.hp)


static func _set_health(s: Dictionary, d: Dictionary, value: float) -> void:
	s["gate_hp" if d.group == "gate" else "hp"] = value


static func _worker(world: RefCounted, d: Dictionary, executor: String) -> bool:
	if executor == "you":
		if float(world.player.hp) <= 0 or not world.working:
			return false
		if d.group != "passage":
			return world.player.pos.distance_to(d.player_point) < float(d.range)
		for raw: Array in d.points:
			if world.player.pos.distance_to(Routes.point(raw)) < float(d.range):
				return true
		return false
	for a: Dictionary in world.survivors:
		if a.id != executor or float(a.hp) <= 0 or a.activity.begins_with("Sheltering") or a.duty.clear_left > 0:
			continue
		var task: String = "Roadwork" if d.group == "road" else "Passage" if d.group == "passage" else "Repair"
		if a.order != task or a.job != d.id:
			return false
		for raw: Array in d.points:
			if a.pos.distance_to(Routes.point(raw)) < 40:
				return true
	return false


static func _reason(world: RefCounted, d: Dictionary) -> String:
	for id: String in d.requires:
		if not world.properties[id].claimed:
			return "Reclaim site"
		if world.remaining(id) > 0:
			return "Clear nearby threats"
	for z: Dictionary in world.zombies:
		if float(z.hp) <= 0:
			continue
		for raw: Array in d.points:
			if z.pos.distance_to(Routes.point(raw)) < 90:
				return "Clear nearby threats"
	return ""


static func _critical(world: RefCounted, d: Dictionary, hp: float) -> bool:
	if hp >= float(d.max) * 0.4:
		return false
	for a: Dictionary in world.survivors:
		if a.id != "ellis" and float(a.hp) > 0 and a.order in ["Guard", "Roadguard", "Home"] and a.pos.distance_to(d.player_point) < 180:
			return true
	return false


static func step(world: RefCounted, target: String, executor: String, dt: float) -> bool:
	var d: Dictionary = describe(world.catalog, target)
	if d.is_empty():
		return false
	var socket: String = "repair:" + target
	var s: Dictionary = state(world, d)
	var hp: float = health(s, d)
	var order: Dictionary = WorkOrders.current(world, socket)
	if hp <= 0 and WorkOrders.pending(order) and order.recipe == "repair_line":
		destroy(world, target)
		order = WorkOrders.current(world, socket)
	var reason: String = _reason(world, d)
	if reason.is_empty() and not _worker(world, d, executor):
		reason = "Need worker at site"
	if not reason.is_empty():
		WorkOrders.block(world, socket, reason)
		return false
	if d.group == "road" and s.phase != "ready":
		return false
	if d.group == "passage" and not s.done:
		return false
	if not WorkOrders.pending(order):
		if hp >= float(d.max) or (hp <= 0 and d.group == "road"):
			return false
		# A broken gate is rebuilt explicitly by the present player.
		if executor != "you":
			if hp <= 0:
				return false
			for id: String in d.requires:
				if not world.safe_connected(id):
					return false
			if world.materials - int(world.balance.gate_repair_cost) < int(world.production.material_reserve) and not _critical(world, d, hp):
				return false
		var recipe: String = "gate_rebuild" if hp <= 0 else "repair_line"
		if not WorkOrders.approve(world, socket, target, WorkRecipes.recipe(world.catalog, recipe), Routes.point(d.points[0])):
			return false
		order = WorkOrders.current(world, socket)
	var before: float = float(order.work_done)
	var completed: bool = WorkOrders.advance(world, socket, executor, dt)
	if order.recipe == "gate_rebuild":
		if completed:
			_set_health(s, d, float(d.max))
			s.open = true
			world.rebuild_routes()
	else:
		var healed: float = (float(order.work_done) - before) * float(world.balance.gate_repair_rate)
		_set_health(s, d, minf(float(d.max), hp + healed))
		if hp <= 0 and health(s, d) > 0:
			s.open = true
			world.rebuild_routes()
		if health(s, d) >= float(d.max) and WorkOrders.pending(order):
			# Discard unused capacity now, so later damage requires another batch.
			completed = WorkOrders.advance(world, socket, executor, float(order.work_required) - float(order.work_done))
	sync(world)
	return completed


static func block(world: RefCounted, target: String, reason: String) -> void:
	WorkOrders.block(world, "repair:" + target, reason)


static func destroy(world: RefCounted, target: String) -> void:
	WorkOrders.cancel(world, "repair:" + target, true)
	sync(world)


static func cancel(world: RefCounted, socket: String) -> bool:
	if not socket.begins_with("repair:") or not WorkOrders.cancel(world, socket):
		return false
	var target: String = socket.trim_prefix("repair:")
	var d: Dictionary = describe(world.catalog, target)
	if not d.is_empty():
		for a: Dictionary in world.survivors:
			if a.job == d.id and a.order in ["Roadwork", "Passage", "Repair"]:
				world.finish_job(a, true)
	sync(world)
	return true


static func sync(world: RefCounted) -> void:
	world.repair_reserved = false
	for id: String in world.properties:
		if WorkOrders.pending(WorkOrders.current(world, "repair:gate:" + id)):
			world.repair_reserved = true
			world.gate_repair_target = id
	for id: String in world.passages:
		world.passages[id].repair_reserved = WorkOrders.pending(WorkOrders.current(world, "repair:passage:" + id))
	for id: String in world.roadworks:
		world.roadworks[id].repair_reserved = WorkOrders.pending(WorkOrders.current(world, "repair:road:" + id))
