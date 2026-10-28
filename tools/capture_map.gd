extends "res://addons/hatchery/testing/capture_runner.gd"
const Exploration = preload("res://scripts/sim/exploration.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.paused = false
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_M
	game._unhandled_input(key)
	if not game.paused or game.hud.section != "Town":
		push_error("M did not open the paused town overview")
		quit(1)
		return
	var before: Dictionary = game.save_state.snapshot(game.world)
	for i: int in range(20):
		game._process(0.05)
	if game.save_state.snapshot(game.world) != before:
		push_error("Town overview advanced authoritative state")
		quit(1)
		return
	if game.hud.town_map.sites.clinic.visible or game.hud.town_map.detail.text.contains("Clinic"):
		push_error("Town overview revealed an unseen site")
		quit(1)
		return
	await frames(3)
	await shot("known_town")
	for p: Dictionary in game.world.catalog.properties:
		game.world.player.pos = game.world.routes.point(p.site)
		Exploration.update(game.world)
	game.hud.refresh(game.world, true)
	game.hud.town_map.sites.clinic.pressed.emit()
	if game.hud.town_map.selected != "clinic" or not game.hud.town_map.detail.text.contains("Unsecured"):
		push_error("Connected map selection failed")
		quit(1)
		return
	var state: Dictionary = game.save_state.snapshot(game.world)
	game.hud.town_map.select_site("relay")
	if game.save_state.snapshot(game.world) != state:
		push_error("Map selection moved or changed the world")
		quit(1)
		return
	game.hud.town_map.select_site("clinic")
	await frames(3)
	await shot("scouted_town")
