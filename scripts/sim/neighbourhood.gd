extends RefCounted
## Authored passages and protected street crossings, separate from ownership.
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func initial(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for d: Dictionary in catalog.passages:
		result[d.id] = {"started": false, "progress": 0.0, "done": false, "open": false, "hp": 0.0, "repair_reserved": false}
	return result


static func nearby(world: RefCounted) -> Dictionary:
	for d: Dictionary in world.catalog.passages:
		for site: Array in d.sites:
			if world.player.pos.distance_to(Routes.point(site)) < float(world.balance.passage_range):
				return d
	return {}


static func owned(world: RefCounted, d: Dictionary) -> bool:
	for id: String in d.requires:
		if not world.properties[id].claimed:
			return false
	return true


static func clear(world: RefCounted, rect: Rect2) -> bool:
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and rect.has_point(z.pos):
			return false
	return true


static func safe_work(world: RefCounted, d: Dictionary) -> bool:
	return owned(world, d) and clear(world, Routes.rectangle(d.area).grow(float(world.balance.passage_danger_range)))


static func context(world: RefCounted, d: Dictionary) -> String:
	if not owned(world, d):
		return "Secure both yards"
	var s: Dictionary = world.passages[d.id]
	if not s.started:
		return "E Passage · %d materials" % int(world.balance.passage_cost)
	if not s.done:
		return "R Build   E Cancel (+%d)   F Assign" % int(WorkOrders.refund(WorkOrders.current(world, "passage:" + str(d.id))).get("materials", 0))
	if float(s.hp) <= 0:
		return "R Rebuild · %d materials" % int(world.balance.gate_repair_cost)
	var repair: String = "   R Repair · %d materials" % int(world.balance.gate_repair_cost) if float(s.hp) < float(world.balance.gate_health) else ""
	return "E %s%s" % ["Close" if s.open else "Open", repair]


static func interact(world: RefCounted, d: Dictionary) -> void:
	var s: Dictionary = world.passages[d.id]
	if not s.done and s.started:
		cancel(world, "passage:" + str(d.id))
		return
	if not safe_work(world, d):
		world.note("Secure both yards and clear the passage before working its gate.")
		return
	if not s.started:
		if not WorkOrders.approve(world, "passage:" + str(d.id), d.id, recipe(world.catalog), world.player.pos):
			world.note("Not enough materials for a fenced passage.")
			return
		s.started = true
		world.note("Passage approved. R builds it; F assigns a worker. Yard fences stay until completion.")
	elif float(s.hp) > 0:
		if s.open:
			for a: Dictionary in [world.player] + world.survivors + world.zombies:
				if float(a.hp) > 0 and Routes.rectangle(d.gate).grow(Routes.RADIUS).has_point(a.pos):
					world.note("Passage gate occupied. Step clear before closing it.")
					return
		s.open = not s.open
		world.rebuild_routes()


static func obstacles(world: RefCounted) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for d: Dictionary in world.catalog.passages:
		var s: Dictionary = world.passages[d.id]
		if not s.done:
			continue
		for rail: Array in d.rails:
			result.append(Routes.rectangle(rail))
		if not s.open and float(s.hp) > 0:
			result.append(Routes.rectangle(d.gate))
	return result


static func openings(world: RefCounted) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for d: Dictionary in world.catalog.passages:
		if world.passages[d.id].done:
			result.append(Routes.rectangle(d.area))
	return result


static func recipe(catalog: Dictionary) -> Dictionary:
	return {"id": "passage", "kind": "construction", "inputs": {"materials": int(catalog.balance.passage_cost)}, "outputs": {}, "seconds": float(catalog.balance.passage_seconds)}


static func cancel(world: RefCounted, socket: String) -> bool:
	if not socket.begins_with("passage:"):
		return false
	var id: String = socket.trim_prefix("passage:")
	if not world.passages.has(id) or not WorkOrders.cancel(world, socket):
		return false
	world.passages[id] = initial(world.catalog)[id]
	for a: Dictionary in world.survivors:
		if a.order == "Passage" and a.job == id:
			a.order = "Hold" if a.id == "ellis" else "Home"
			a.job = ""
	world.note("Passage cancelled. Materials returned.")
	return true


static func _occupied(world: RefCounted, d: Dictionary) -> bool:
	for a: Dictionary in [world.player] + world.survivors + world.zombies:
		# Downed people still occupy the footprint; dead zombies do not.
		if a.has("raid") and float(a.hp) <= 0:
			continue
		for raw: Array in d.rails + [d.gate]:
			if Routes.rectangle(raw).grow(Routes.RADIUS).has_point(a.pos):
				return true
	return false


static func step(world: RefCounted, dt: float) -> void:
	for d: Dictionary in world.catalog.passages:
		var s: Dictionary = world.passages[d.id]
		var socket: String = "passage:" + str(d.id)
		if not s.started:
			continue
		if not safe_work(world, d):
			WorkOrders.block(world, socket, "Reclaim site" if not owned(world, d) else "Clear nearby threats")
			continue
		var executor: String = "you" if world.working and nearby(world).get("id") == d.id and float(world.player.hp) > 0 else ""
		for a: Dictionary in world.survivors:
			if executor == "you":
				break
			if a.order == "Passage" and a.job == d.id and float(a.hp) > 0 and not a.activity.begins_with("Sheltering"):
				for site: Array in d.sites:
					if a.pos.distance_to(Routes.point(site)) < 40 and (executor.is_empty() or str(a.id) < executor):
						executor = a.id
		if executor.is_empty():
			WorkOrders.block(world, socket, "Need worker at site")
			continue
		if not s.done:
			var completed: bool = WorkOrders.advance(world, socket, executor, dt, not _occupied(world, d))
			s.progress = float(WorkOrders.current(world, socket).work_done)
			if completed:
				s.done = true
				s.hp = float(world.balance.gate_health)
				world.rebuild_routes()
				world.note("Passage ready. E opens the gate.")
		elif float(s.hp) < float(world.balance.gate_health):
			_repair(world, s, dt)


static func _repair(world: RefCounted, s: Dictionary, dt: float) -> void:
	if not s.repair_reserved:
		if world.materials < int(world.balance.gate_repair_cost):
			return
		world.materials -= int(world.balance.gate_repair_cost)
		s.repair_reserved = true
	var broken: bool = float(s.hp) <= 0
	s.hp = minf(float(world.balance.gate_health), float(s.hp) + dt * float(world.balance.gate_repair_rate))
	if broken:
		s.open = true
		world.rebuild_routes()
	if float(s.hp) >= float(world.balance.gate_health):
		s.repair_reserved = false


static func bump(world: RefCounted, z: Dictionary, intended: Vector2) -> bool:
	for d: Dictionary in world.catalog.passages:
		var s: Dictionary = world.passages[d.id]
		if not s.done or s.open or float(s.hp) <= 0:
			continue
		if Routes.rectangle(d.gate).grow(Routes.RADIUS).has_point(intended):
			if float(z.cooldown) <= 0:
				s.hp = maxf(0, float(s.hp) - float(world.balance.gate_damage) * ZombieTypes.stat(world.catalog, z, "breach"))
				z.cooldown = ZombieTypes.stat(world.catalog, z, "cooldown")
				if float(s.hp) <= 0:
					world.rebuild_routes()
					world.note("Passage gate breached. Check both connected yards.")
			return true
	return false


static func link_reason(world: RefCounted, d: Dictionary) -> String:
	if not owned(world, d):
		return "uncontrolled yard"
	for id: String in d.requires:
		if world.remaining(id) > 0:
			return "hostile yard"
	if not clear(world, Routes.rectangle(d.area)):
		return "hostile in corridor"
	if d.has("rails"):
		var s: Dictionary = world.passages[d.id]
		if not s.done:
			return "passage not built"
		if float(s.hp) <= 0:
			return "passage gate breached"
		return "" if s.open else "passage gate closed"
	for id: String in d.barriers:
		var b: Dictionary = world.roadworks[id]
		if b.phase not in ["ready", "dismantling"] or float(b.hp) <= 0:
			return "street boundary open"
	for id: String in d.requires:
		if not world.properties[id].open:
			return "yard gate closed"
	return ""


static func safe_connected(world: RefCounted, id: String) -> bool:
	if not world.properties.home.claimed or world.remaining("home") > 0:
		return false
	var reached: Array[String] = ["home"]
	var index: int = 0
	while index < reached.size():
		for d: Dictionary in world.catalog.passages + world.catalog.crossings:
			if not d.requires.has(reached[index]) or not link_reason(world, d).is_empty():
				continue
			for next: String in d.requires:
				if world.remaining(next) == 0 and not reached.has(next):
					reached.append(next)
		index += 1
	return reached.has(id)


static func summary(world: RefCounted) -> String:
	var lines: PackedStringArray = []
	for d: Dictionary in world.catalog.passages + world.catalog.crossings:
		var known: bool = false
		for id: String in d.requires:
			known = known or (id != "home" and world.properties[id].looted)
		if known:
			var reason: String = link_reason(world, d)
			lines.append(d.name + ": " + ("usable" if reason.is_empty() else reason))
	return "\n".join(lines)


static func work_areas(world: RefCounted) -> Array[Rect2]:
	var areas: Array[Rect2] = []
	for p: Dictionary in world.catalog.properties:
		if safe_connected(world, p.id):
			areas.append(Routes.rectangle(p.rect).grow(1))
	for d: Dictionary in world.catalog.passages + world.catalog.crossings:
		if link_reason(world, d).is_empty() and safe_connected(world, d.requires[0]) and safe_connected(world, d.requires[1]):
			areas.append(Routes.rectangle(d.area).grow(1))
	return areas
