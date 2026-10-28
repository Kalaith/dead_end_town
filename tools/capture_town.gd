extends "res://addons/hatchery/testing/capture_runner.gd"
const Exploration = preload("res://scripts/sim/exploration.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world.messages.clear()
	for entry: Array in [["greenhouse", "market_row_shells"], ["hall", "civic_block_shells"], ["relay", "east_works_shells"]]:
		var p: Dictionary = game.world.definition(entry[0])
		game.world.player.pos = game.world.routes.point(p.site)
		Exploration.update(game.world)
		game.camera.position = Vector2(game.world.player.pos.x, 400)
		game.camera.force_update_scroll()
		game.hud.refresh(game.world, false)
		game.view.queue_redraw()
		await frames(3)
		await shot(entry[1])
		var stock: int = game.world.materials
		game.world.interact()
		if game.world.properties[p.id].claimed or game.world.materials != stock:
			push_error("Development shell granted a claim/reward")
			quit(1)
			return
		game.world.messages.clear()
