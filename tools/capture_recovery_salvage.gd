extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_recovery.gd")


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
	game.world = Checks.quiet()
	game.world.properties.home.claimed = false
	game.world.player.pos = Vector2(30, 610)
	game.world.player.hp = 50.0
	game.world.materials = 0
	game.world.food = 0
	game.view.world = game.world
	game.camera.position = Vector2(640, 570)
	game.camera.force_update_scroll()
	game.command("resume")
	key(true)
	await frames(2)
	for i: int in range(200):
		game._process(0.05)
	if game.world.recovery_salvage.west < 9.9 or game.world.materials != 0:
		push_error("Held R did not produce timed west recovery work")
		quit(1)
		return
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("recovery_salvage")
	key(false)
	await frames(2)
	game.command("menu")
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before:
		push_error("Pause advanced emergency salvage")
		quit(1)
		return
	game.command("resume")
	key(true)
	await frames(2)
	for i: int in range(200):
		game._process(0.05)
	key(false)
	await frames(2)
	if game.world.materials != 2:
		push_error("Recovery work did not deliver one two-material batch")
		quit(1)
		return
	game.world.materials = 23
	key(true)
	await frames(2)
	for i: int in range(401):
		game._process(0.05)
	key(false)
	await frames(2)
	if game.world.materials != 24 or not game.world.context().is_empty():
		push_error("Cap overflowed or left a misleading recovery prompt")
		quit(1)
		return
