extends "res://addons/hatchery/testing/capture_runner.gd"


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		game.world.claim(id)
	game.world.properties.home.open = true
	game.world.rebuild_routes()
	game.world.player.pos = Vector2(1080, 350)
	game.world.interact()
	game.world.player.pos = Vector2(1080, 800)
	game.world.interact()
	game.world.player.pos = Vector2(360, 445)
	game.command("team")
	_choose(game, "mara", "garden")
	_choose(game, "paige", "garage")
	if game.world.survivors[0].job != "garden" or game.world.survivors[1].job != "garage":
		push_error("Team selectors did not assign independent work.")
		quit(1)
		return
	await frames(3)
	await shot("team_orders")
	game.command("resume")
	await seconds(0.2)
	game.paused = true
	for i: int in range(240):
		game.world.step(0.05)
	if game.world.garden_progress <= 0 or float(game.world.workshop.progress) <= 0:
		push_error("Independent UI-assigned workers failed to reach their sites.")
		quit(1)
		return
	game.command("team")
	await frames(3)
	await shot("team_working")
	game.hud.team_orders.rows.paige.picker.show_popup()
	await frames(3)
	await shot("team_choices")


func _choose(game: Node, id: String, task: String) -> void:
	var picker: OptionButton = game.hud.team_orders.rows[id].picker
	for index: int in range(picker.item_count):
		if picker.get_item_metadata(index) == task:
			picker.select(index)
			picker.item_selected.emit(index)
			return
	push_error("Missing team choice: " + task)
