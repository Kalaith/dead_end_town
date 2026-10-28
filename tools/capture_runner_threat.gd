extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_runner.gd")


func key(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_S
	event.keycode = KEY_S
	event.pressed = pressed
	Input.parse_input_event(event)


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.prepared()
	game.view.world = game.world
	game.command("resume")
	game._process(0.05)
	var z: Dictionary = Checks.runner(game.world)
	if z.runner.phase != "tell":
		push_error("Runner did not telegraph through the live game")
		quit(1)
		return
	game.world.messages.clear()
	game.camera.position = game.world.player.pos
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("runner_lunge")
	game.command("menu")
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before:
		push_error("Pause advanced the committed Runner tell")
		quit(1)
		return
	game.command("resume")
	key(true)
	await frames(2)
	for i: int in range(7):
		game._process(0.05)
	key(false)
	await frames(2)
	for i: int in range(15):
		game._process(0.05)
	if game.world.player.hp != 100.0 or z.runner.phase != "recover":
		push_error("Real S sidestep failed to evade the committed lunge")
		quit(1)
		return
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("runner_recovery")
