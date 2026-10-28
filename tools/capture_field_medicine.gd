extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_field_medicine.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")


func key(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	event.keycode = KEY_R
	event.pressed = pressed
	Input.parse_input_event(event)


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.prepared()
	game.view.world = game.world
	game.command("resume")
	key(true)
	await frames(2)
	for i: int in range(30):
		game._process(0.05)
	key(false)
	await frames(2)
	if game.world.medicine != 11 or not game.world.field_care.has("mara"):
		push_error("Held R did not start one paid field treatment")
		quit(1)
		return
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("field_treatment")
	game.command("menu")
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before:
		push_error("Pause advanced field treatment")
		quit(1)
		return
	game.command("resume")
	key(true)
	await frames(2)
	for i: int in range(40):
		game._process(0.05)
		if Equipment.person(game.world, "mara").hp == 70:
			break
	key(false)
	await frames(2)
	if Equipment.person(game.world, "mara").hp != 70 or game.world.medicine != 11 or not game.world.field_care.is_empty():
		push_error("Field treatment failed to heal once for the paid dose")
		quit(1)
		return
	game.world.player.pos = Vector2(1080, 800)
	game.command("menu")
	game.hud.refresh(game.world, true)
	game.hud.show_section("Loadouts")
	await frames(3)
	await shot("field_bag_loadout")
