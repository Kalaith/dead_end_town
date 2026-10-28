extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_recovery.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.quiet()
	game.world.food = 0
	game.world.materials = 0
	game.world.properties.home.claimed = false
	game.world.player.pos = Vector2(1080, 580)
	game.world.player.hp = 0.0
	game.world.survivors[0].hp = 0.0
	game.world.step(0.05)
	game.view.world = game.world
	game.paused = false
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if not game.paused or not game.hud.defeat_menu.visible or game.hud.menu.visible or game.save_state.snapshot(game.world) != before:
		push_error("Defeat panel did not freeze the world before recovery")
		quit(1)
		return
	game.command("resume")
	game._process(0.2)
	if not game.paused or game.save_state.snapshot(game.world) != before:
		push_error("Resume bypassed pending defeat")
		quit(1)
		return
	await frames(3)
	await shot("defeat_choice")
	game.hud.defeat_menu.load_button.pressed.emit()
	if not game.world.defeat_pending or game.save_state.snapshot(game.world) != before:
		push_error("Unavailable load altered pending recovery")
		quit(1)
		return
	game.hud.defeat_menu.recover_button.pressed.emit()
	if game.paused or game.world.defeat_pending or game.world.player.hp != 50 or game.world.survivors[0].hp != 25 or game.world.food != 0 or game.world.materials != 0:
		push_error("Connected Recover failed the empty-stock foothold")
		quit(1)
		return
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("west_foothold")
