extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_production.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world = Checks.staffed()
	game.view.world = game.world
	game.view.queue_redraw()
	game.set_process(false)
	game.hud.refresh(game.world, true)
	game.paused = false
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	key.keycode = KEY_J
	key.pressed = true
	Input.parse_input_event(key)
	await frames(2)
	if not game.paused or game.hud.section != "Work":
		push_error("J did not pause into the work page")
		quit(1)
		return
	key.pressed = false
	Input.parse_input_event(key)
	var board: Control = game.hud.work_menu
	board.mode.select(1)
	board.mode.item_selected.emit(1)
	if game.world.production.mode != "once":
		push_error("Work board did not issue one-batch command")
		quit(1)
		return
	Firearms.step(game.world, 5.0)
	game.hud.refresh(game.world, true)
	await frames(3)
	await shot("work_board")
	board.target.value = 12
	board.mode.select(2)
	board.mode.item_selected.emit(2)
	Firearms.step(game.world, 10.0)
	Firearms.step(game.world, 1.0)
	if int(game.world.firearms.bullets) != 12 or game.world.production.reason != "Target met":
		push_error("Work board target did not stop production")
		quit(1)
		return
	game.hud.refresh(game.world, true)
	await frames(3)
	await shot("work_target_met")
	game.hud.show_section("Street")
	await frames(3)
	await shot("planning")
