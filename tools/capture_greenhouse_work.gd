extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_greenhouse.gd")
const Roster = preload("res://scripts/sim/roster.gd")


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.prepared()
	game.view.world = game.world
	game.camera.position = Vector2(3960, 360)
	game.camera.force_update_scroll()
	game.command("resume")
	key(KEY_E, true)
	await frames(2)
	key(KEY_E, false)
	await frames(2)
	if not game.world.greenhouse.started:
		push_error("Real E input did not approve greenhouse restoration")
		quit(1)
		return
	key(KEY_R, true)
	await frames(2)
	for i: int in range(120):
		game._process(0.05)
	key(KEY_R, false)
	await frames(2)
	if not is_equal_approx(game.world.greenhouse.progress, 6.0):
		push_error("Real R input did not perform six seconds of restoration")
		quit(1)
		return
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("greenhouse_restoration")
	game.command("work")
	var row: Dictionary = game.hud.construction_menu.rows["restore:greenhouse"]
	var picker: OptionButton = row.picker
	for index: int in range(picker.item_count):
		if picker.get_item_metadata(index) == "oliver":
			picker.select(index)
			picker.item_selected.emit(index)
	game.hud.refresh(game.world, true)
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before or Roster.person(game.world, "oliver").order != "Greenhouse":
		push_error("Connected greenhouse board assignment or pause failed")
		quit(1)
		return
	await frames(3)
	await shot("greenhouse_work_board")
	game.command("resume")
	for i: int in range(365):
		game._process(0.05)
	if not game.world.greenhouse.done or Roster.person(game.world, "oliver").order != "Hold":
		push_error("Temporary restoration did not finish and return Oliver to Hold")
		quit(1)
		return
	game.command("team")
	picker = game.hud.team_orders.rows.oliver.picker
	for index: int in range(picker.item_count):
		if picker.get_item_metadata(index) == "greenhouse":
			picker.select(index)
			picker.item_selected.emit(index)
	game.command("resume")
	for i: int in range(600):
		game._process(0.05)
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("greenhouse_growing")
	game.command("menu")
	before = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before:
		push_error("Pause advanced greenhouse food")
		quit(1)
		return
	await frames(3)
	game.hud.show_section("Street")
	await frames(3)
	await shot("greenhouse_food_status")
	game.command("resume")
	var food: int = game.world.food
	for i: int in range(605):
		game._process(0.05)
		if game.world.provisions.harvested == 4:
			break
	if game.world.food != food + 4 or game.world.provisions.harvested != 4:
		push_error("Connected grower did not deliver four Food once")
		quit(1)
		return
