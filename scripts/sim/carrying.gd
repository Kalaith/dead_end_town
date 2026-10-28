extends RefCounted
const Equipment = preload("res://scripts/sim/equipment.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")


static func initial() -> Dictionary:
	return {"patient": "", "target": "", "progress": 0.0}


static func occupied(world: RefCounted) -> bool:
	return not str(world.carry.patient).is_empty()


static func nearby(world: RefCounted) -> Dictionary:
	var chosen: Dictionary = {}
	var distance: float = float(world.balance.carry_range)
	for a: Dictionary in world.survivors:
		var next: float = a.pos.distance_to(world.player.pos)
		if float(a.hp) > 0 or carried(world, a.id) or next > distance or not world.routes.line_clear(world.player.pos, a.pos):
			continue
		if next < distance or chosen.is_empty() or str(a.id) < str(chosen.id):
			chosen = a
			distance = next
	return chosen


static func clear(world: RefCounted, a: Dictionary) -> bool:
	return not Combat.danger(world, a.pos, 170) and not Combat.danger(world, world.player.pos, 170)


static func press(world: RefCounted) -> bool:
	if occupied(world):
		if not drop(world):
			world.note("Reach a clear held shelter to put the casualty down.")
		return true
	var a: Dictionary = nearby(world)
	if a.is_empty():
		return false
	world.carry.target = a.id
	world.carry.progress = 0.0
	return true


static func step(world: RefCounted, dt: float) -> void:
	if occupied(world):
		sync(world)
		return
	if not world.interacting or float(world.player.hp) <= 0 or str(world.carry.target).is_empty():
		world.carry.target = ""
		world.carry.progress = 0.0
		return
	var a: Dictionary = nearby(world)
	if a.is_empty() or a.id != world.carry.target or not clear(world, a):
		world.carry.progress = 0.0
		return
	world.carry.progress = minf(float(world.balance.carry_seconds), float(world.carry.progress) + dt)
	if world.carry.progress >= float(world.balance.carry_seconds):
		world.working = false
		world.carry.patient = a.id
		world.carry.target = ""
		world.carry.progress = 0.0
		sync(world)


static func sync(world: RefCounted) -> void:
	if occupied(world):
		Equipment.person(world, world.carry.patient).pos = world.player.pos


static func release(world: RefCounted) -> bool:
	var was_lifting: bool = not str(world.carry.target).is_empty()
	world.carry.target = ""
	world.carry.progress = 0.0
	return was_lifting


static func shelter(world: RefCounted) -> Dictionary:
	for p: Dictionary in world.catalog.properties:
		if world.properties[p.id].claimed and world.remaining(p.id) == 0 and world.player.pos.distance_to(Routes.point(p.site)) < 85 and not Combat.danger(world, Routes.point(p.site), 170):
			return p
	return {}


static func drop(world: RefCounted) -> bool:
	if not occupied(world):
		return false
	var p: Dictionary = shelter(world)
	if p.is_empty():
		return false
	for offset: Vector2 in [Vector2(-60, 20), Vector2(60, 20), Vector2(-60, -20), Vector2(60, -20), Vector2(0, 40)]:
		var point: Vector2 = Routes.point(p.site) + offset
		if world.routes.walkable(point) and Routes.rectangle(p.rect).has_point(point):
			Equipment.person(world, world.carry.patient).pos = point
			world.carry = initial()
			return true
	return false


static func abandon(world: RefCounted) -> void:
	# Ordinary defeat must not silently carry a casualty through a teleport.
	sync(world)
	world.carry = initial()


static func context(world: RefCounted) -> String:
	if occupied(world):
		return ("E Drop " if not shelter(world).is_empty() else "Carrying ") + str(Equipment.person(world, world.carry.patient).name)
	var a: Dictionary = nearby(world)
	if a.is_empty():
		return ""
	if float(world.carry.progress) > 0:
		return "Carry %s · %d%%" % [a.name, int(100 * float(world.carry.progress) / float(world.balance.carry_seconds))]
	return "Hold E Carry " + str(a.name)


static func carrier(world: RefCounted, patient: String) -> String:
	if world.carry.patient == patient:
		return "you"
	for id: String in world.rescue_jobs:
		if world.rescue_jobs[id].phase == "carry" and world.rescue_jobs[id].patient == patient:
			return id
	return ""


static func carried(world: RefCounted, patient: String) -> bool:
	return not carrier(world, patient).is_empty()


static func burdened(world: RefCounted, id: String) -> bool:
	return occupied(world) if id == "you" else world.rescue_jobs.has(id) and world.rescue_jobs[id].phase == "carry"
