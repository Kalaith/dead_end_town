extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_slice.gd")
const Objective = preload("res://scripts/sim/slice_objective.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world = Checks.ready()
	game.view.world = game.world
	game.world.survivors[0].pos = Vector2(1080, 350)
	game.world.assign_survivor("mara", "garden")
	game.world.survivors[1].pos = Vector2(360, 445)
	game.world.assign_survivor("paige", "home")
	game.world.pressure.next = 65.0
	game.command("team")
	game.hud.menu.get_child(0).scroll_vertical = 0
	await frames(5)
	if game.hud.watch_button.disabled or not game.hud.watch_button.visible:
		push_error("Prepared street did not expose the watch action.")
		quit(1)
		return
	game.hud.watch_button.pressed.emit()
	if game.world.slice_state.phase != "watch":
		push_error("Connected watch button failed to start the objective.")
		quit(1)
		return
	game.hud.menu.get_child(0).scroll_vertical = 0
	await frames(5)
	await shot("neighbourhood_watch")
	# Stage just before completion, then let the real process show its result.
	game.world.slice_state.held = 59.8
	game.command("resume")
	await seconds(0.5)
	if not game.paused or game.world.slice_state.phase != "complete" or not game.hud.pause_title.text.contains("SLICE COMPLETE"):
		push_error("Slice completion did not pause and show its result.")
		quit(1)
		return
	await shot("slice_complete")
	game.hud.first_button.pressed.emit()
	await seconds(0.1)
	if game.paused or game.world.slice_state.phase != "complete":
		push_error("Continue did not preserve the earned finish.")
		quit(1)
