extends RefCounted
## One authoritative actor per authored rescue; no hidden waiting actor or rescue timer.
const Routes = preload("res://scripts/sim/routes.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")


static func definition(catalog: Dictionary, id: String) -> Dictionary:
	for d: Dictionary in catalog.survivors:
		if d.id == id:
			return d
	return {}


static func person(world: RefCounted, id: String) -> Dictionary:
	for a: Dictionary in world.survivors:
		if a.id == id:
			return a
	return {}


static func _create(world: RefCounted, d: Dictionary, pos: Vector2) -> Dictionary:
	var a: Dictionary = world.actor(d.id, d.name, pos, float(world.balance.survivor_health))
	a.order = d.order
	a.anchor = pos
	Jobs.initialise(a, d.duty)
	if d.id == "ellis":
		a.duty.anchor = world.balance.home_respawn.duplicate()
	world.survivors.append(a)
	return a


static func start(world: RefCounted) -> void:
	_create(world, definition(world.catalog, "mara"), Routes.point(world.balance.mara_start))


static func recruit(world: RefCounted, id: String) -> bool:
	var d: Dictionary = definition(world.catalog, id)
	if d.is_empty() or d.site == "home" or not world.properties[d.site].looted or not person(world, id).is_empty():
		return false
	_create(world, d, Routes.point(world.definition(d.site).site) + Routes.point(d.offset))
	world.note(d.line)
	return true
