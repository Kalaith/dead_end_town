extends RefCounted
## Persistent duties and temporary work. Guard/follower orders never join this queue.
const Routes = preload("res://scripts/sim/routes.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Repairs = preload("res://scripts/sim/repairs.gd")


static func initialise(a: Dictionary, role: String) -> void:
	var anchor: Array = [a.anchor.x, a.anchor.y] if a.anchor is Vector2 else a.anchor.duplicate()
	a.duty = {"role": role, "anchor": anchor, "temporary": false, "return_task": "", "return_anchor": anchor.duplicate(), "retry": 0.0, "clear_left": 0.0}


static func current(catalog: Dictionary, a: Dictionary) -> String:
	match a.order:
		"Garden":
			return "garden"
		"Workshop", "Build":
			return a.job
		"Clinic":
			return "clinic"
		"Ammo":
			return "ammo"
		"Passage":
			return "passage:" + str(a.job)
		"Roadwork":
			return "work:" + str(a.job)
		"Repair":
			return "repair:" + str(a.job)
		"Idle":
			return a.duty.role
		"Roadguard":
			for d: Dictionary in catalog.barricades:
				var center: Vector2 = Routes.point(d.center)
				var post: Vector2 = center + center.direction_to(Routes.point(d.site)) * float(catalog.balance.barricade_stand_offset)
				if a.anchor.distance_to(post) < 10:
					return "guard:" + str(d.id)
		"Follow", "Hold", "Engage":
			return str(a.order).to_lower()
	return "home"


static func temporary(task: String) -> bool:
	return task.begins_with("work:") or task.begins_with("passage:") or task.begins_with("repair:")


static func remember(world: RefCounted, a: Dictionary, task: String) -> void:
	for order: Dictionary in world.orders.sites.values():
		if WorkOrders.pending(order) and order.executor == a.id:
			order.executor = ""
			order.phase = "blocked"
			order.blocked_reason = "Need worker at site"
	if temporary(task):
		if not a.duty.temporary:
			a.duty.return_task = current(world.catalog, a)
			a.duty.return_anchor = [a.anchor.x, a.anchor.y]
		a.duty.temporary = true
	else:
		a.duty.temporary = false
		a.duty.return_task = ""
		if task not in ["follow", "hold", "engage"]:
			a.duty.role = task
			a.duty.anchor = [a.anchor.x, a.anchor.y]
	a.duty.retry = 0.0


static func resume(world: RefCounted, a: Dictionary) -> void:
	var task: String = str(a.duty.return_task) if a.duty.temporary else str(a.duty.role)
	var anchor: Array = a.duty.return_anchor.duplicate() if a.duty.temporary else a.duty.anchor.duplicate()
	a.duty.temporary = false
	a.duty.return_task = ""
	if not world.assign_survivor(a.id, task, false):
		if task in ["garden", "garage", "ammo", "clinic"]:
			a.order = "Idle"
			a.job = ""
			a.anchor = a.pos
			return
		world.assign_survivor(a.id, "hold" if a.id == "ellis" else "home", false)
	elif task == "hold":
		a.anchor = Routes.point(anchor)


static func finish(world: RefCounted, a: Dictionary) -> void:
	if a.duty.temporary:
		resume(world, a)


static func abort(world: RefCounted, a: Dictionary) -> void:
	if a.duty.temporary:
		finish(world, a)
	else:
		a.order = "Idle"
		a.job = ""
		a.anchor = a.pos
		a.activity = "Waiting for approved work"


static func food_target(world: RefCounted) -> int:
	return (world.survivors.size() + 1) * 2 + int(world.balance.food_target_buffer)


static func _task(order: Dictionary) -> String:
	match order.recipe:
		"clinic":
			return "clinic"
		"garden":
			return "garden"
		"workshop", "armour":
			return "garage"
		"passage":
			return "passage:" + str(order.target)
		"road_build", "road_remove":
			return "work:" + str(order.target)
		"repair_line", "gate_rebuild", "legacy_repair":
			var parts: PackedStringArray = str(order.target).split(":")
			return ("work:" if parts[0] == "road" else "passage:" if parts[0] == "passage" else "repair:") + parts[1]
	return ""


static func assignment_reason(world: RefCounted, socket: String, a: Dictionary) -> String:
	var order: Dictionary = WorkOrders.current(world, socket)
	if not WorkOrders.pending(order) or order.kind == "production" or _task(order).is_empty():
		return "Project is no longer available"
	if a.is_empty() or float(a.hp) <= 0:
		return "Recover this survivor first"
	if not _safe(world, order, a):
		return "Clear the site and secure a home route"
	return ""


static func assign_order(world: RefCounted, socket: String, id: String) -> bool:
	for a: Dictionary in world.survivors:
		if a.id == id:
			var reason: String = assignment_reason(world, socket, a)
			if not reason.is_empty():
				world.note(reason + ".")
				return false
			return _take(world, a, _task(WorkOrders.current(world, socket)))
	world.note("That survivor has not joined the team.")
	return false


static func _take(world: RefCounted, a: Dictionary, task: String) -> bool:
	var saved: Dictionary = a.duty.duplicate(true)
	var previous: String = current(world.catalog, a)
	var anchor: Array = [a.anchor.x, a.anchor.y]
	if not world.assign_survivor(a.id, task, false):
		return false
	a.duty = saved
	if not saved.temporary:
		a.duty.return_task = previous
		a.duty.return_anchor = anchor
	a.duty.temporary = true
	a.duty.retry = 0.0
	return true


static func _safe(world: RefCounted, order: Dictionary, a: Dictionary) -> bool:
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and z.pos.distance_to(Routes.point(order.stand)) < 170:
			return false
	var required: Array = []
	if order.recipe in Repairs.IDS:
		required = Repairs.describe(world.catalog, order.target).requires
	elif order.recipe == "passage":
		for d: Dictionary in world.catalog.passages:
			if d.id == order.target:
				required = d.requires
	elif str(order.recipe).begins_with("road_"):
		for d: Dictionary in world.catalog.barricades:
			if d.id == order.target:
				required = d.requires
	else:
		required = [order.target]
	var local: bool = a.pos.distance_to(Routes.point(order.stand)) < 80
	for id: String in required:
		if not world.properties[id].claimed or world.remaining(id) > 0:
			return false
		# A nearby worker can finish a prepaid field project. Remote assignment needs a safe route.
		if not local and not world.safe_connected(id):
			return false
	return true


static func _choose(world: RefCounted, a: Dictionary) -> String:
	var candidates: Array[Dictionary] = []
	for order: Dictionary in world.orders.sites.values():
		if not WorkOrders.pending(order) or order.kind == "production" or not _safe(world, order, a):
			continue
		var task: String = _task(order)
		var occupied: bool = false
		for other: Dictionary in world.survivors:
			if other.id != a.id and float(other.hp) > 0 and current(world.catalog, other) == task:
				occupied = true
		if occupied:
			continue
		var priority: int = 1 if order.priority else 2
		if order.recipe in Repairs.IDS:
			var d: Dictionary = Repairs.describe(world.catalog, order.target)
			if Repairs.health(Repairs.state(world, d), d) < float(d.max) * 0.4:
				priority = 0
		if a.duty.role == "general" and priority == 2:
			continue
		candidates.append({"task": task, "priority": priority, "sequence": int(order.sequence), "id": order.id})
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if left.priority != right.priority:
			return int(left.priority) < int(right.priority)
		return int(left.sequence) < int(right.sequence) if left.sequence != right.sequence else str(left.id) < str(right.id))
	if not candidates.is_empty():
		return candidates[0].task
	if a.duty.role == "general":
		if world.garden_done and world.safe_connected("garden") and world.food < food_target(world):
			return "garden"
		if (world.production.mode == "once" or (world.production.mode == "repeat" and int(world.firearms.bullets) < int(world.production.target))) and world.properties.munitions.looted and world.safe_connected("munitions"):
			return "ammo"
	return ""


static func _needed(world: RefCounted, a: Dictionary) -> bool:
	var task: String = current(world.catalog, a)
	for order: Dictionary in world.orders.sites.values():
		if WorkOrders.pending(order) and _task(order) == task:
			return true
	if task.begins_with("work:"):
		var s: Dictionary = world.roadworks.get(task.trim_prefix("work:"), {})
		return not s.is_empty() and (s.phase in ["building", "dismantling"] or (s.phase == "ready" and float(s.hp) < float(world.balance.barricade_health)))
	if task.begins_with("passage:"):
		var s: Dictionary = world.passages.get(task.trim_prefix("passage:"), {})
		return not s.is_empty() and s.started and (not s.done or float(s.hp) < float(world.balance.gate_health))
	if task.begins_with("repair:"):
		var s: Dictionary = world.properties.get(task.trim_prefix("repair:"), {})
		return not s.is_empty() and float(s.gate_hp) < float(world.balance.gate_health)
	if task == "garden":
		return world.garden_started and (not world.garden_done or (a.duty.return_task == "general" and world.food < food_target(world)))
	if task == "ammo":
		return world.production.mode == "once" or (world.production.mode == "repeat" and int(world.firearms.bullets) < int(world.production.target))
	return false


static func step(world: RefCounted, dt: float) -> void:
	for a: Dictionary in world.survivors:
		a.duty.retry = maxf(0.0, float(a.duty.retry) - dt)
		a.duty.clear_left = maxf(0.0, float(a.duty.clear_left) - dt)
		if float(a.hp) <= 0:
			continue
		if a.order in ["Build", "Garden", "Workshop", "Roadwork", "Passage", "Repair", "Ammo", "Clinic"]:
			for z: Dictionary in world.zombies:
				if float(z.hp) > 0 and z.pos.distance_to(a.anchor) < 170:
					a.duty.clear_left = float(world.balance.work_clear_seconds)
		if a.duty.temporary and not _needed(world, a):
			finish(world, a)
		if a.order == "Idle" and a.duty.role in ["garden", "garage", "clinic"]:
			var approved: bool = world.clinic.started if a.duty.role == "clinic" else world.garden_started if a.duty.role == "garden" else world.workshop.started
			if approved:
				world.assign_survivor(a.id, a.duty.role, false)
		if a.order != "Idle" or a.duty.role not in ["builder", "general"] or a.duty.retry > 0:
			continue
		a.duty.retry = float(world.balance.work_retry_seconds)
		var task: String = _choose(world, a)
		if task.is_empty():
			continue
		_take(world, a, task)
