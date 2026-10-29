extends RefCounted
## The area boss holds a post on the only road out and is leashed to it. Its death is permanent and opens the exit.
const Pressure = preload("res://scripts/sim/pressure.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Wandering = preload("res://scripts/sim/wandering.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const HOME: String = "boss"
const POST_TOLERANCE: float = 12.0
const EXIT_REACH: float = 60.0
const CONFIRM_SECONDS: float = 6.0


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


## The area after this one in campaign order, or "" at the end of the campaign.
static func destination(catalog: Dictionary) -> String:
	var ids: Array = catalog.areas.map(func(entry: Dictionary) -> String: return str(entry.id))
	var next: int = ids.find(catalog.area.id) + 1
	return str(ids[next]) if next < ids.size() else ""


## The area before this one in campaign order, or "" in the first area.
static func origin(catalog: Dictionary) -> String:
	var ids: Array = catalog.areas.map(func(entry: Dictionary) -> String: return str(entry.id))
	var previous: int = ids.find(catalog.area.id) - 1
	return str(ids[previous]) if previous >= 0 else ""


static func at_entrance(world: RefCounted) -> bool:
	return world.catalog.has("entrance") and Routes.rectangle(world.catalog.entrance.rect).grow(EXIT_REACH).has_point(world.player.pos)


## The way back is never blocked by a boss, but it asks like the exit does.
static func enter_interact(world: RefCounted) -> void:
	if origin(world.catalog).is_empty():
		world.note("This is the way you came in. There is nowhere behind it yet.")
	elif float(world.exit_pending) > 0:
		world.exit_pending = 0.0
		world.travel_requested = origin(world.catalog)
	else:
		world.exit_pending = CONFIRM_SECONDS
		world.note("Go back through the %s to the previous area? Your team and gear come too, and up to %d of each stock. Press E again to confirm." % [str(world.catalog.entrance.name).to_lower(), int(world.balance.area_carry_cap)])


static func entrance_context(world: RefCounted) -> String:
	if origin(world.catalog).is_empty():
		return "Entrance / nothing behind it yet"
	return "E to confirm going back" if float(world.exit_pending) > 0 else "E Go back"


## The last area's exit ends the campaign with its own closing line.
static func _final(catalog: Dictionary) -> bool:
	return bool(catalog.exit.get("final", false))


static func context(world: RefCounted) -> String:
	if not at_exit(world):
		return ""
	if not defeated(world):
		return "Blocked / the %s holds the road" % _name(world.catalog)
	if destination(world.catalog).is_empty():
		return "E Leave town" if _final(world.catalog) else "Exit / nothing lies beyond yet"
	return "E to confirm leaving" if float(world.exit_pending) > 0 else "E Leave the area"


## Leaving needs a second press so it is never an accident; a rule-bound shortage of stock is stated up front.
static func interact(world: RefCounted) -> void:
	if not defeated(world):
		world.note("The %s still holds the way out." % _name(world.catalog))
	elif destination(world.catalog).is_empty():
		if _final(world.catalog):
			world.campaign_ended = true
		else:
			world.note("Nothing lies beyond the bridge yet.")
	elif float(world.exit_pending) > 0:
		world.exit_pending = 0.0
		world.travel_requested = destination(world.catalog)
	else:
		world.exit_pending = CONFIRM_SECONDS
		world.note("Leave %s? Your team and gear come too, and up to %d of each stock. Press E again to confirm." % [str(world.catalog.area.name), int(world.balance.area_carry_cap)])


## Announce the fall once, when it was seen alive in this session.
static func step(world: RefCounted, dt: float) -> void:
	world.exit_pending = maxf(0.0, float(world.exit_pending) - dt)
	if not at_exit(world) and not at_entrance(world):
		world.exit_pending = 0.0
	var boss: Dictionary = find(world)
	if boss.is_empty():
		return
	if float(boss.hp) > 0:
		world.boss_seen_alive = true
	elif world.boss_seen_alive:
		world.boss_seen_alive = false
		world.note("The %s is down. The way out (%s) is open." % [_name(world.catalog), str(world.catalog.exit.name).to_lower()])


## The boss's own name for messages, lower-cased: each area has a different one.
static func _name(catalog: Dictionary) -> String:
	return ZombieTypes.type_name(catalog, str(catalog.boss.kind)).to_lower()
