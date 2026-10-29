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
	_fittings(data, saves)
	z.hp = 0.0
	Vehicle.hit(world, 1000.0)
	_expect("a wrecked van ejects the driver and stays wrecked", not Vehicle.driving(world) and float(world.vehicle.hull) == 0.0 and world.context() != "E Drive the van")
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


## Riders, the ambulance run and repair.
func _fittings(data: Dictionary, saves: RefCounted) -> void:
	var world := World.new(data)
	_clear(world)
	world.player.hp = 100.0
	var mara: Dictionary = world.survivors[0]
	mara.hp = 80.0
	mara.order = "Follow"
	world.player.pos = Vehicle.pos(world) + Vector2(0, 40)
	mara.pos = world.player.pos + Vector2(20, 0)
	world.interact()
	_expect("a close follower boards with the driver", Vehicle.driving(world) and world.vehicle.riders == [mara.id] and mara.pos.distance_to(Vehicle.pos(world)) < 0.01)
	var restored: RefCounted = saves.restore(JSON.parse_string(JSON.stringify(saves.snapshot(world))))
	_expect("riders save and load", restored != null and restored.vehicle.riders == [mara.id])
	world.move_input = Vector2(0, -1)
	for i: int in range(20):
		world.step(0.05)
	_expect("the rider moves with the van", mara.pos.distance_to(Vehicle.pos(world)) < 0.01)
	var z: Dictionary = world.zombies[0]
	z.hp = 60.0
	z.pos = Vehicle.pos(world) + Vector2(20, 0)
	z.cooldown = 0.0
	for i: int in range(30):
		world.step(0.05)
	_expect("a zombie at the hull cannot hurt the rider", float(mara.hp) == 80.0)
	z.hp = 0.0
	world.move_input = Vector2.ZERO
	world.vehicle.speed = 0.0
	world.interact()
	_expect("getting out sets the rider down on foot and clear", not Vehicle.driving(world) and world.vehicle.riders.is_empty() and mara.pos.distance_to(world.player.pos) > 5.0 and world.routes.walkable(mara.pos))
	# Ambulance: boarding with a casualty in arms.
	var w2 := World.new(data)
	_clear(w2)
	w2.player.hp = 100.0
	var patient: Dictionary = w2.survivors[0]
	patient.hp = 0.0
	w2.carry.patient = patient.id
	# Away from any shelter, where E would otherwise put the casualty down.
	w2.vehicle.x = 1500.0
	w2.vehicle.y = 900.0
	w2.player.pos = Vehicle.pos(w2) + Vector2(0, 40)
	w2.interact()
	w2.step(0.05)
	_expect("a carried casualty rides along", Vehicle.driving(w2) and patient.pos.distance_to(w2.player.pos) < 0.01 and w2.carry.patient == patient.id)
	w2.interact()
	_expect("getting out keeps the casualty in arms", not Vehicle.driving(w2) and w2.carry.patient == patient.id)
	# Repair: paid once, partial work kept, mobility returns.
	var w3 := World.new(data)
	_clear(w3)
	Vehicle.hit(w3, 1000.0)
	w3.player.pos = Vehicle.pos(w3) + Vector2(0, 40)
	w3.materials = 10
	_expect("the wrecked van offers repair", w3.context().contains("Repair"))
	w3.working = true
	w3.step(1.0)
	_expect("repair prepays 4 materials once", w3.materials == 6 and bool(w3.vehicle.repair_paid))
	w3.working = false
	w3.step(1.0)
	w3.working = true
	for i: int in range(36):
		w3.step(0.25)
	_expect("repair finishes with 200 hull and no second charge", float(w3.vehicle.hull) == 200.0 and w3.materials == 6 and not bool(w3.vehicle.repair_paid))
	w3.working = false
	_expect("a repaired van can be driven again", w3.context().begins_with("E Drive the van"))
	var short := World.new(data)
	_clear(short)
	Vehicle.hit(short, 50.0)
	short.materials = 1
	short.player.pos = Vehicle.pos(short) + Vector2(0, 40)
	short.working = true
	short.step(1.0)
	_expect("without materials nothing is spent or repaired", short.materials == 1 and float(short.vehicle.hull) == 250.0)
	# Saves from before the fittings.
	var raw41: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(w3)))
	raw41.schema_version = 41
	raw41.erase("spits")
	raw41.erase("spit_hits")
	for key: String in ["riders", "repair_paid", "repair_progress"]:
		raw41.vehicle.erase(key)
	var up: RefCounted = saves.restore(raw41)
	_expect("a schema 41 save gains empty riders and hazards", up != null and up.vehicle.riders.is_empty() and up.spits.is_empty())


func _clear(world: RefCounted) -> void:
	for z: Dictionary in world.zombies:
		z.hp = 0.0


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
