extends RefCounted
## The area boss holds a post on the only road out and is leashed to it. Its death is permanent and opens the exit.
const Pressure = preload("res://scripts/sim/pressure.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Wandering = preload("res://scripts/sim/wandering.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const HOME: String = "boss"
const POST_TOLERANCE: float = 12.0
const EXIT_REACH: float = 60.0


static func configured(catalog: Dictionary) -> bool:
	return catalog.has("boss")


## The boss and its escorts, in a stable order. These are the area's non-property residents.
static func resident_ids(catalog: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	if configured(catalog):
		ids.append(str(catalog.boss.id))
		for i: int in range(catalog.boss.escorts.size()):
			ids.append(escort_id(catalog, i))
	return ids


static func escort_id(catalog: Dictionary, index: int) -> String:
	return "%s_escort_%d" % [catalog.boss.id, index]


static func add(world: RefCounted) -> void:
	if not configured(world.catalog):
		return
	var config: Dictionary = world.catalog.boss
	world.zombies.append(_actor(world, config.id, config.kind, config.post))
	for i: int in range(config.escorts.size()):
		world.zombies.append(_actor(world, escort_id(world.catalog, i), "shambler", config.escorts[i]))


static func _actor(world: RefCounted, id: String, kind: String, pos: Array) -> Dictionary:
	var z: Dictionary = world.actor(id, ZombieTypes.type_name(world.catalog, kind), Routes.point(pos), ZombieTypes.health(world.catalog, kind))
	z.home = HOME
	z.raid = false
	Pressure.give_kind(world.catalog, z, kind)
	return z


static func find(world: RefCounted) -> Dictionary:
	if configured(world.catalog):
		for z: Dictionary in world.zombies:
			if z.id == world.catalog.boss.id:
				return z
	return {}


static func guards(world: RefCounted, z: Dictionary) -> bool:
	return configured(world.catalog) and z.id == world.catalog.boss.id


## An area without a boss is open. Otherwise the exit opens when the boss is dead.
static func defeated(world: RefCounted) -> bool:
	var boss: Dictionary = find(world)
	return boss.is_empty() or float(boss.hp) <= 0


static func exit_rect(catalog: Dictionary) -> Rect2:
	return Routes.rectangle(catalog.exit.rect)


static func at_exit(world: RefCounted) -> bool:
	return configured(world.catalog) and exit_rect(world.catalog).grow(EXIT_REACH).has_point(world.player.pos)


## A target beyond the leash is ignored, so the boss can only be drawn a limited way from its post.
static func leashed(world: RefCounted, target: Dictionary) -> Dictionary:
	if target.is_empty():
		return target
	var config: Dictionary = world.catalog.boss
	return target if Routes.point(config.post).distance_to(target.pos) <= float(config.leash) else {}


static func return_to_post(world: RefCounted, z: Dictionary, dt: float) -> void:
	var post: Vector2 = Routes.point(world.catalog.boss.post)
	if z.pos.distance_to(post) <= POST_TOLERANCE:
		return
	var next: Vector2 = post if world.routes.travel_clear(z.pos, post) else world.routes.waypoint(z.pos, post)
	Wandering.advance(world, z, post if next.is_equal_approx(z.pos) else next, dt)


## Announce the fall once, when it was seen alive in this session.
static func step(world: RefCounted) -> void:
	var boss: Dictionary = find(world)
	if boss.is_empty():
		return
	if float(boss.hp) > 0:
		world.boss_seen_alive = true
	elif world.boss_seen_alive:
		world.boss_seen_alive = false
		world.note("The baboon is down. The way out (%s) is open." % str(world.catalog.exit.name).to_lower())
