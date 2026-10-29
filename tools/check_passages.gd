extends SceneTree
## Passage check: each authored passage joins its two lots only once it is built and open. The four rear gates between the
## island rows are included, so the back-to-back lots really connect.
## Run: Godot --headless --path . --script res://tools/check_passages.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const STEP: float = 8.0
const LIMIT: int = 400
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	for d: Dictionary in data.passages:
		var from: Vector2 = Routes.point(d.sites[0])
		var to: Vector2 = Routes.point(d.sites[1])
		var closed: int = _walk(_world(data, d, false), from, to)
		var open: int = _walk(_world(data, d, true), from, to)
		var straight: int = int(from.distance_to(to) / STEP)
		_expect("%s is a short cut only when open (%d open, %d closed, %d straight)" % [d.id, open, closed, straight], open >= 0 and open <= straight * 13 / 10 + 3 and (closed < 0 or closed > open + 10))
	quit(failures)


func _world(data: Dictionary, d: Dictionary, open: bool) -> RefCounted:
	var world := World.new(data)
	var state: Dictionary = world.passages[d.id]
	state.started = true
	state.done = true
	state.open = open
	state.hp = float(data.balance.gate_health)
	world.rebuild_routes()
	return world


## Steps the game's own walking needs between the two ends, or -1 if it stalls.
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
