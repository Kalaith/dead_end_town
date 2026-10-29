extends SceneTree
## Tips follow the world: each lesson appears at its moment, goes away once learned, and never changes the game.
## Run: Godot --headless --path . --script res://tools/check_tips.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Tips = preload("res://scripts/sim/tips.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	_expect("every tip has text and a rule", Catalog.problems(data).is_empty())
	var world := World.new(data)
	for z: Dictionary in world.zombies:
		z.hp = 0.0
	world.step(0.05)
	_expect("the first tip is to move", Tips.current(world) == "move")
	var start: Vector2 = world.player.pos
	world.player.pos = start + Vector2(200, 0)
	world.step(0.05)
	_expect("it goes once you have walked", Tips.current(world) == "gate_repair")
	var z: Dictionary = World.actor("tip_z", "Shambler", world.player.pos + Vector2(100, 0), 60.0)
	z.home = "home"
	z.raid = false
	z.cooldown = 100.0
	world.zombies.append(z)
	world.step(0.05)
	_expect("a close zombie teaches the swing first", Tips.current(world) == "swing")
	world.attack()
	z.hp = 0.0
	world.step(0.05)
	_expect("swinging ends it", Tips.current(world) == "gate_repair")
	world.properties.home.gate_hp = float(world.balance.gate_health)
	world.step(0.05)
	_expect("a sound gate teaches opening it", Tips.current(world) == "gate_open")
	world.properties.home.open = true
	world.step(0.05)
	_expect("an open gate points at the first yard", Tips.current(world) == "reclaim")
	for id: String in world.properties:
		if id != "home":
			world.properties[id].claimed_once = true
			break
	world.step(0.05)
	_expect("a reclaimed yard ends the opening lessons", Tips.current(world).is_empty())
	var mara: Dictionary = world.survivors[0]
	mara.hp = 0.0
	mara.pos = world.player.pos + Vector2(30, 0)
	world.step(0.05)
	_expect("a downed survivor within reach teaches the lift", Tips.current(world) == "carry")
	world.carry.patient = mara.id
	world.step(0.05)
	_expect("carrying teaches the drop-off", Tips.current(world) == "carry_drop")
	world.carry = Carrying.initial()
	mara.pos = world.player.pos + Vector2(300, 0)
	world.step(0.05)
	_expect("putting them down ends it", Tips.current(world).is_empty())
	var late := World.new(data)
	late.elapsed = 120.0
	late.step(0.05)
	_expect("a game past a minute counts the basics as taught", Tips.current(late) != "move")
	_expect("tips never touched the stock", int(world.food) == int(data.balance.starting_food) and int(world.materials) == int(data.balance.starting_materials))
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
