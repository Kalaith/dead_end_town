extends SceneTree
## A hurt survivor gives ground, and a downed one can be lifted with a zombie nearby but not on top of them.
## Run: Godot --headless --path . --script res://tools/check_rescue_feel.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	var world := World.new(data)
	for z: Dictionary in world.zombies:
		z.hp = 0.0
	var spot: Vector2 = _open(world)
	var mara: Dictionary = world.survivors[0]
	mara.order = "Follow"
	mara.hp = 20.0
	mara.pos = spot
	world.player.pos = spot + Vector2(-30, 0)
	var z: Dictionary = World.actor("test_z", "Shambler", spot + Vector2(60, 0), 60.0)
	z.home = "home"
	z.raid = false
	world.zombies.append(z)
	z.cooldown = 100.0
	var before: float = mara.pos.distance_to(z.pos)
	world.step(0.05)
	_expect("and says so", str(mara.activity) == "Falling back")
	z.cooldown = 100.0
	for i: int in range(10):
		world.step(0.05)
		z.cooldown = 100.0
	_expect("a hurt survivor backs away from a close zombie", mara.pos.distance_to(z.pos) > before)
	mara.hp = 100.0
	var healthy: Vector2 = mara.pos
	for i: int in range(4):
		world.step(0.05)
		z.cooldown = 100.0
	_expect("a healthy survivor does not retreat", str(mara.activity) != "Falling back" and healthy.distance_to(mara.pos) >= 0.0)
	mara.hp = 0.0
	mara.pos = spot
	world.player.pos = spot + Vector2(-30, 0)
	z.pos = spot + Vector2(120, 0)
	_expect("a zombie 120 px away does not block a lift", Carrying.clear(world, mara))
	z.pos = spot + Vector2(40, 0)
	_expect("a zombie 40 px away does", not Carrying.clear(world, mara) and Carrying.context(world).begins_with("Zombie too close"))
	z.hp = 0.0
	world.interacting = true
	Carrying.press(world)
	for i: int in range(60):
		world.step(0.05)
	_expect("holding E lifts the downed survivor", Carrying.occupied(world))
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _open(world: RefCounted) -> Vector2:
	for x: int in range(300, 1400, 40):
		for y: int in range(300, 1400, 40):
			var p := Vector2(x, y)
			if world.routes.walkable(p) and world.routes.walkable(p + Vector2(120, 0)) and world.routes.walkable(p - Vector2(30, 0)) and world.routes.line_clear(p, p + Vector2(120, 0), true):
				return p
	return Vector2(500, 500)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
