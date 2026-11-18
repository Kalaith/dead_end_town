extends SceneTree
## Ring check: on foot, once the home gate is open, the player can still reach the bridge, the exit and every lot site,
## and the way the horde takes from the bridge to home is walkable end to end.
## Run: Godot --headless --path . --script res://tools/checks/check_ring.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const STEP: float = 8.0
const LIMIT: int = 2000
var failures: int = 0


func _init() -> void:
	for entry: Dictionary in Catalog.registry().areas:
		_area(Catalog.read(str(entry.id)))
	quit(failures)


func _area(data: Dictionary) -> void:
	print("-- ", data.area.name)
	var world := World.new(data)
	world.properties.home.open = true
	world.rebuild_routes()
	var start: Vector2 = Routes.point(data.balance.player_start)
	var targets: Dictionary = {"bridge approach": Routes.point(data.pressure.routes[0].approach), "exit": Boss.exit_rect(data).get_center(), "boss post": Routes.point(data.boss.post)}
	for p: Dictionary in data.properties:
		targets["site of " + str(p.id)] = Routes.point(p.site)
	for label: String in targets:
		var steps: int = _walk(world, start, targets[label])
		_expect("%s is reachable (%s)" % [label, "%d steps" % steps if steps >= 0 else "grid path only"], steps >= 0 or _path(world, start, targets[label]))
	var entry: Vector2 = Routes.point(data.pressure.routes[0].entry)
	var horde: int = _walk(world, entry, Routes.point(data.pressure.routes[0].approach))
	_expect("the bridge entry reaches its approach point (%d steps)" % horde, horde >= 0)


## True when the game's grid search finds a route, which is what survivors and zombies follow. The straight-line follower
## below can clip a lot corner even when a route exists.
func _path(world: RefCounted, from: Vector2, to: Vector2) -> bool:
	return world.routes.travel_clear(from, to) or not world.routes.waypoint(from, to).is_equal_approx(from)


## Follows the same waypoint walking the game uses; -1 when it gets stuck or runs out of steps.
func _walk(world: RefCounted, from: Vector2, to: Vector2) -> int:
	var pos: Vector2 = from
	for i: int in range(LIMIT):
		if pos.distance_to(to) <= STEP * 1.5:
			return i
		var next: Vector2 = to if world.routes.travel_clear(pos, to) else world.routes.waypoint(pos, to)
		var moved: Vector2 = world.routes.move(pos, next, STEP)
		if moved.is_equal_approx(pos):
			return -1
		pos = moved
	return -1


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
