extends "res://addons/hatchery/testing/capture_runner.gd"
const World = preload("res://scripts/sim/world.gd")
const Roster = preload("res://scripts/sim/roster.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world.player.pos = Vector2(3960, 350)
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	game.camera.position = Vector2(3960, 400)
	game.camera.force_update_scroll()
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("greenhouse_search")
	game.paused = false
	game.world.interact()
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if not game.paused or not game.hud.rescue_menu.visible or game.hud.menu.visible or not game.hud.rescue_menu.home_button.disabled or game.save_state.snapshot(game.world) != before:
		push_error("Rescue introduction did not pause before authoritative clocks")
		quit(1)
		return
	game.command("resume")
	game._process(0.2)
	if not game.paused or game.save_state.snapshot(game.world) != before:
		push_error("Resume bypassed the pending introduction")
		quit(1)
		return
	await frames(3)
	await shot("oliver_introduction")
	game.hud.rescue_menu.hold_button.pressed.emit()
	if game.paused or not game.world.rescue_intro.is_empty() or Roster.person(game.world, "oliver").order != "Hold":
		push_error("Connected rescue choice did not hold Oliver and resume")
		quit(1)
		return
	game.command("team")
	await frames(3)
	await shot("oliver_team")
