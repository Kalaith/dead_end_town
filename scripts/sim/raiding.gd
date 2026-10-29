extends RefCounted
## Raiders hunt buildings that still need zombies, otherwise follow the road out. No saved state.
const Routes = preload("res://scripts/sim/routes.gd")
const Plan = preload("res://scripts/sim/migration_plan.gd")
const Wandering = preload("res://scripts/sim/wandering.gd")
const EXIT_RANGE: float = 30.0
const ARRIVE_RADIUS: float = 120.0
const SETTLE_RADIUS: float = 130.0
const BACK_INSET: float = 40.0
const SWAY_ANGLE: float = 0.7
const SWAY_RATE: float = 0.9


static func step(world: RefCounted, z: Dictionary, dt: float) -> void:
	if _arriving(world, z, dt):
		return
	var inside: Dictionary = _property_at(world, z.pos)
	if not inside.is_empty() and _willing(world, z, inside):
		_settle(world, z, inside, dt)
		return
	var need: Dictionary = _nearest_need(world, z)
	if not need.is_empty():
		_approach(world, z, need, dt)
		return
	var exit: Vector2 = _exit(world, z)
	if z.pos.distance_to(exit) < EXIT_RANGE:
		z.hp = -1.0
		return
	_head_to(world, z, exit, dt)


## A new arrival follows its entrance's approach road before it hunts anything. Hunting by straight-line distance
## would send it at the nearest lot, often across a back fence, instead of along the road that leads to the street.
static func _arriving(world: RefCounted, z: Dictionary, dt: float) -> bool:
	var m: Variant = z.get("migration")
	if not m is Dictionary or m.phase != "inward":
		return false
	var route: Dictionary = Plan.route(world.catalog, str(m.origin))
	if route.is_empty():
		return false
	var approach: Vector2 = Routes.point(route.approach)
	if z.pos.distance_to(approach) > ARRIVE_RADIUS:
		_head_to(world, z, approach, dt)
		return true
	m.phase = "seeking"
	return false


## Removes raiders that walked off the map. Killed raiders keep their corpses (hp == 0).
static func sweep(world: RefCounted) -> void:
	var retained: Array[Dictionary] = []
	for z: Dictionary in world.zombies:
		if float(z.hp) >= 0:
			retained.append(z)
	world.zombies = retained


## Walk to the back of the yard, then wander within reach of it.
static func _settle(world: RefCounted, z: Dictionary, p: Dictionary, dt: float) -> void:
	var back: Vector2 = _back(p)
	if z.pos.distance_to(back) > SETTLE_RADIUS and world.routes.waypoint(z.pos, back) != z.pos:
		_head_to(world, z, back, dt)
	else:
		Wandering.step(world, z, dt)


static func _approach(world: RefCounted, z: Dictionary, p: Dictionary, dt: float) -> void:
	var site: Vector2 = Routes.point(p.site)
	if world.routes.waypoint(z.pos, site) != z.pos:
		_head_to(world, z, site, dt)
	elif Routes.rectangle(p.rect).has_point(z.pos):
		Wandering.step(world, z, dt)
	else:
		# Shut out by a closed gate: push at the gate so it takes the damage.
		Wandering.advance(world, z, Routes.point(p.gate), dt)


## Raiders drift along their path rather than ruling a straight line; only chasing is direct.
static func _head_to(world: RefCounted, z: Dictionary, target: Vector2, dt: float) -> void:
	var next: Vector2 = world.routes.waypoint(z.pos, target)
	var direction: Vector2 = z.pos.direction_to(next if not next.is_equal_approx(z.pos) else target)
	var sway: float = sin(world.elapsed * SWAY_RATE + float(z.id.hash() % 628) / 100.0) * SWAY_ANGLE
	Wandering.advance(world, z, z.pos + direction.rotated(sway) * 100.0, dt)


static func _back(p: Dictionary) -> Vector2:
	var rect: Rect2 = Routes.rectangle(p.rect)
	var gate_top: bool = Routes.point(p.gate).y == rect.position.y
	return Vector2(rect.get_center().x, rect.end.y - BACK_INSET if gate_top else rect.position.y + BACK_INSET)


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
