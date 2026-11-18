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
	var fight := World.new(data)
	fight.elapsed = 120.0
	for z2: Dictionary in fight.zombies:
		z2.hp = 0.0
	var foe: Dictionary = World.actor("tip_foe", "Shambler", fight.player.pos + Vector2(100, 0), 60.0)
	foe.home = "home"
	foe.raid = false
	foe.cooldown = 100.0
	fight.zombies.append(foe)
	fight.player.swing = 0.1
	fight.step(0.05)
	_expect("a fight with a team teaches the orders (" + Tips.current(fight) + ")", Tips.current(fight) == "orders")
	fight.order("Hold")
	fight.step(0.05)
	_expect("giving an order ends it", Tips.current(fight) != "orders")
	fight.firearms.owned = true
	fight.firearms.bullets = 5
	fight.step(0.05)
	_expect("a pistol with bullets in a fight teaches shooting", Tips.current(fight) == "pistol")
	fight.shoot()
	fight.step(0.05)
	_expect("firing ends it", Tips.current(fight) != "pistol")
	var loud := World.new(data)
	loud.elapsed = 120.0
	for z4: Dictionary in loud.zombies:
		z4.hp = 0.0
	loud.properties.home.gate_hp = float(loud.balance.gate_health)
	loud.properties.hardware.claimed_once = true
	loud.noise.events.append({"id": 1, "emitter": "you", "category": "pistol", "key": "k", "x": 0.0, "y": 0.0, "radius": 100.0, "updated": 0.0, "expires": 1000.0})
	loud.step(0.05)
	_expect("a loud noise teaches what it draws (" + Tips.current(loud) + ")", Tips.current(loud) == "noise")
	var kit := World.new(data)
	kit.elapsed = 120.0
	for z3: Dictionary in kit.zombies:
		z3.hp = 0.0
	kit.properties.home.gate_hp = float(kit.balance.gate_health)
	kit.properties.home.open = true
	kit.properties.hardware.claimed_once = true
	kit.workshop.armour_done = true
	kit.step(0.05)
	_expect("a finished armour cache teaches the loadout", Tips.current(kit) == "loadout")
	kit.equipment.iron = "mara"
	kit.properties.clinic.looted = true
	kit.survivors[0].hp = 40.0
	kit.player.pos += Vector2(0, 400)
	kit.step(0.05)
	_expect("a hurt survivor with no field bag teaches assigning it (" + Tips.current(kit) + ")", Tips.current(kit) == "field_bag")
	kit.equipment.field_bag = "mara"
	kit.step(0.05)
	_expect("assigning it ends the tip", Tips.current(kit) != "field_bag")
	_expect("tips never touched the stock", int(world.food) == int(data.balance.starting_food) and int(world.materials) == int(data.balance.starting_materials))
	_areas_and_board()
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


## Each later area greets a fresh arrival once; paid-for work points at the work board until it is opened.
func _areas_and_board() -> void:
	for id: String in ["office", "industrial"]:
		var area: RefCounted = World.new(Catalog.read(id))
		for z: Dictionary in area.zombies:
			z.hp = 0.0
		area.tips.moved = true
		area.step(0.05)
		_expect("arriving in the %s shows its welcome (%s)" % [id, Tips.current(area)], Tips.current(area) == "area_" + id and not Tips.text(area, Tips.current(area)).is_empty())
		for i: int in range(140):
			area.step(0.1)
		_expect("the %s welcome goes after a while" % id, Tips.current(area) != "area_" + id)
	var data: Dictionary = Catalog.read()
	var board := World.new(data)
	for z: Dictionary in board.zombies:
		z.hp = 0.0
	board.elapsed = 100.0
	board.properties.home.open = true
	board.properties.garden.looted = true
	board.properties.garden.claimed_once = true
	board.properties.garden.claimed = true
	board.player.pos = Vector2(board.definition("garden").site[0], board.definition("garden").site[1])
	board.materials = 100
	board.interact()
	board.player.pos += Vector2(0, 300)
	board.step(0.05)
	_expect("paid-for work teaches the work board (%s)" % Tips.current(board), Tips.current(board) == "work_board")
	Tips.saw_board(board)
	board.step(0.05)
	_expect("opening the board ends it", Tips.current(board) != "work_board")


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
