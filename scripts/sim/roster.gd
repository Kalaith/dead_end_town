extends RefCounted
## One authoritative actor per authored rescue; no hidden waiting actor or rescue timer.
const Routes = preload("res://scripts/sim/routes.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")


static func definition(catalog: Dictionary, id: String) -> Dictionary:
	for d: Dictionary in catalog.survivors:
		if d.id == id:
			return d
	return {}


## The lot that holds a survivor: a facility kind for the first five, or the lot whose search names them.
static func lot(catalog: Dictionary, d: Dictionary) -> String:
	if d.site != "search":
		return str(d.site) if d.site == "home" else Facility.resolve(catalog, str(d.site))
	for p: Dictionary in catalog.properties:
		if p.has("search") and p.search.get("survivor") == d.id:
			return str(p.id)
	return ""


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
	var at: String = lot(world.catalog, d) if not d.is_empty() else ""
	if d.is_empty() or at.is_empty() or at == "home" or not world.properties[at].looted or not person(world, id).is_empty():
		return false
	_create(world, d, Routes.point(world.definition(at).site) + Routes.point(d.offset))
	if not str(d.intro).is_empty():
		world.rescue_intro = id
	world.note(d.line)
	return true


## Someone whose lot was searched before they were written into it (an older save) is found there now, as if just
## searched. Returns the ids recruited; a current save never needs any.
static func catch_up(world: RefCounted) -> Array[String]:
	var found: Array[String] = []
	for p: Dictionary in world.catalog.properties:
		if not p.has("search") or str(p.search.get("survivor", "")).is_empty() or not world.properties[p.id].looted:
			continue
		var id: String = str(p.search.survivor)
		if person(world, id).is_empty() and recruit(world, id):
			found.append(id)
	return found


static func dismiss(world: RefCounted, task: String) -> bool:
	var d: Dictionary = definition(world.catalog, world.rescue_intro)
	if d.is_empty() or task not in ["hold", "follow", "home"]:
		return false
	if task == "home" and not world.safe_connected(lot(world.catalog, d)):
		return false
	if not world.assign_survivor(d.id, task, false):
		return false
	world.rescue_intro = ""
	return true
