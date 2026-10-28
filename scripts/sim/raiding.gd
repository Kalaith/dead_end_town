extends RefCounted
## Raiders hunt buildings that still need zombies, otherwise follow the road out. No saved state.
const Routes = preload("res://scripts/sim/routes.gd")
const Wandering = preload("res://scripts/sim/wandering.gd")
const EXIT_RANGE: float = 30.0


static func step(world: RefCounted, z: Dictionary, dt: float) -> void:
	var inside: Dictionary = _property_at(world, z.pos)
	if not inside.is_empty() and _settles(world, z, inside):
		Wandering.step(world, z, dt)
		return
	var need: Dictionary = _nearest_need(world, z)
	if not need.is_empty():
		_head_to(world, z, Routes.point(need.site), dt)
		return
	var exit: Vector2 = _exit(world, z)
	if z.pos.distance_to(exit) < EXIT_RANGE:
		z.hp = -1.0
		return
	_head_to(world, z, exit, dt)


## Removes raiders that walked off the map. Killed raiders keep their corpses (hp == 0).
static func sweep(world: RefCounted) -> void:
	var retained: Array[Dictionary] = []
	for z: Dictionary in world.zombies:
		if float(z.hp) >= 0:
			retained.append(z)
	world.zombies = retained


static func _head_to(world: RefCounted, z: Dictionary, target: Vector2, dt: float) -> void:
	var next: Vector2 = world.routes.waypoint(z.pos, target)
	# With no open path, press straight on so closed gates take the damage.
	Wandering.advance(world, z, target if next.is_equal_approx(z.pos) else next, dt)


## A building keeps its hidden quota: a raider inside stays only while the yard is not over quota.
static func _settles(world: RefCounted, z: Dictionary, p: Dictionary) -> bool:
	if world.remaining(p.id) > int(p.hidden_zombies):
		return false
	return _willing(world, z, p)


## Whether this raider would stay in this building, fixed by ids so it needs no saved roll.
static func _willing(world: RefCounted, z: Dictionary, p: Dictionary) -> bool:
	return (z.id + p.id).hash() % 100 < int(world.balance.settle_percent)


static func _nearest_need(world: RefCounted, z: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = INF
	for p: Dictionary in world.catalog.properties:
		if world.remaining(p.id) >= int(p.hidden_zombies) or not _willing(world, z, p):
			continue
		var distance: float = z.pos.distance_to(Routes.point(p.site))
		if distance < best_distance:
			best = p
			best_distance = distance
	return best


static func _property_at(world: RefCounted, pos: Vector2) -> Dictionary:
	for p: Dictionary in world.catalog.properties:
		if Routes.rectangle(p.rect).has_point(pos):
			return p
	return {}


## Each raider keeps one road exit, picked from its id so it never flip-flops.
static func _exit(world: RefCounted, z: Dictionary) -> Vector2:
	var routes: Array = world.catalog.pressure.routes
	return Routes.point(routes[z.id.hash() % routes.size()].entry)
