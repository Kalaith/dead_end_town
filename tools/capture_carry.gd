extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for carrying: a downed survivor ringed and listed, the carry prompt with drop-off rings, then the drop.
## Run through tools/Capture.ps1 -Tour res://tools/capture_carry.gd.


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	town.command("resume")
	var world: RefCounted = town.world
	for z: Dictionary in world.zombies:
		z.hp = 0.0
	var home: Vector2 = Vector2(float(world.definition("home").site[0]), float(world.definition("home").site[1]))
	var mara: Dictionary = world.survivors[0]
	mara.order = "Hold"
	mara.hp = 0.0
	mara.pos = home + Vector2(330, 200)
	world.player.pos = home + Vector2(270, 200)
	await seconds(0.6)
	await shot("carry_casualty_marked")
	_key(true)
	await seconds(0.5)
	await shot("carry_lifting")
	await seconds(2.0)
	_key(false)
	await seconds(0.3)
	world.player.pos = home + Vector2(330, 160)
	await seconds(0.6)
	await shot("carry_dropoff_guide")
	world.player.pos = home + Vector2(20, 30)
	await seconds(0.6)
	await shot("carry_dropoff_ready")
	_key(true)
	await frames(3)
	_key(false)
	await seconds(0.6)
	await shot("carry_dropped")


## E as a real engine event, so the game sees both the press and the release.
func _key(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = pressed
	Input.parse_input_event(event)
