extends SceneTree
## Van check: boarding, acceleration and stopping distance, collision, engine noise, hull damage, ejection, save and
## schema 40 migration. Run: Godot --headless --path . --script res://tools/check_vehicle.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read("office")
	_expect("the suburb has no van", not bool(World.new(Catalog.read()).vehicle.present))
	var world := World.new(data)
	_clear(world)
	_expect("the office has an undamaged van", bool(world.vehicle.present) and float(world.vehicle.hull) == 300.0)
	world.player.hp = 100.0
	world.player.pos = Vehicle.pos(world) + Vector2(0, 40)
	_expect("the prompt offers it", world.context() == "E Drive the van")
	world.step(1.0)
	_expect("an idle van makes no noise", world.noise.events.is_empty())
	world.interact()
	_expect("E boards", Vehicle.driving(world))
	world.move_input = Vector2(0, -1)
	var top: float = 0.0
	for i: int in range(20):
		world.step(0.05)
		top = maxf(top, float(world.vehicle.speed))
	_expect("full throttle reaches top speed", top > 290.0)
	_expect("it makes engine noise", not world.noise.events.is_empty() and world.noise.events[0].category == "engine")
	_expect("the player rides with it", world.player.pos.distance_to(Vehicle.pos(world)) < 0.01)
	world.move_input = Vector2.ZERO
	world.vehicle.x = 2080.0
	world.vehicle.y = 365.0
	world.vehicle.speed = 300.0
	var before: Vector2 = Vehicle.pos(world)
	for i: int in range(40):
		world.step(0.05)
	var stop: float = Vehicle.pos(world).distance_to(before)
	_expect("releasing the throttle stops it within 80 px (%.0f)" % stop, absf(float(world.vehicle.speed)) < 0.01 and stop < 80.0)
	world.move_input = Vector2(0, -1)
	for i: int in range(400):
		world.step(0.05)
	_expect("driving on, it stops against something solid", float(world.vehicle.speed) == 0.0 and Vehicle.fits(world, Vehicle.pos(world), float(world.vehicle.heading)))
	world.move_input = Vector2.ZERO
	world.step(0.1)
	var heading: float = float(world.vehicle.heading)
	world.move_input = Vector2(1, 0)
	world.step(0.1)
	_expect("steering without speed does not turn it", is_equal_approx(heading, float(world.vehicle.heading)))
	# Hull takes the bites; the occupant does not.
	var z: Dictionary = world.zombies[0]
	z.hp = 60.0
	z.pos = Vehicle.pos(world) + Vector2(30, 0)
	z.cooldown = 0.0
	world.move_input = Vector2.ZERO
	var hp: float = float(world.player.hp)
	for i: int in range(60):
		world.step(0.05)
	_expect("a zombie damages the hull, not the driver", float(world.vehicle.hull) < 300.0 and float(world.player.hp) == hp)
	var saves := SaveState.new(data, "user://check_vehicle.json")
	var raw: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(world)))
	var loaded: RefCounted = saves.restore(raw)
	_expect("driving state saves and loads", loaded != null and Vehicle.driving(loaded) and is_equal_approx(float(loaded.vehicle.hull), float(world.vehicle.hull)))
	var old: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(world)))
	old.erase("vehicle")
	old.schema_version = 40
	var upgraded: RefCounted = saves.restore(old)
	_expect("a schema 40 save gains an undriven van", upgraded != null and not Vehicle.driving(upgraded) and float(upgraded.vehicle.hull) == 300.0)
	z.hp = 0.0
	Vehicle.hit(world, 1000.0)
	_expect("a wrecked van ejects the driver and stays wrecked", not Vehicle.driving(world) and float(world.vehicle.hull) == 0.0 and world.context() != "E Drive the van")
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _clear(world: RefCounted) -> void:
	for z: Dictionary in world.zombies:
		z.hp = 0.0


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
