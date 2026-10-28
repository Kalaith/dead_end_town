extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_passage_orders.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world = Checks.prepared()
	Neighbourhood.step(game.world, 2.0)
	game.world.properties.garden.claimed = false
	Neighbourhood.step(game.world, 1.0)
	game.view.world = game.world
	game.view.queue_redraw()
	game.set_process(false)
	game.hud.refresh(game.world, true)
	game.command("work")
	if game.hud.work_menu.visible:
		push_error("Construction work board revealed an undiscovered bullet recipe")
		quit(1)
		return
	await frames(3)
	await shot("passage_work_board")
	var stock: int = game.world.materials
	game.hud.construction_menu.rows["passage:north"].cancel.pressed.emit()
	if game.world.materials <= stock or game.world.passages.north.started:
		push_error("Connected cancellation button did not return materials")
		quit(1)
		return
	game.world.properties.garden.claimed = true
	game.world.player.pos = Vector2(600, 400)
	game.world.interact()
	game.world.working = true
	game.world.survivors[0].pos = Vector2(720, 400)
	game.world.survivors[0].hp = 0.0
	Neighbourhood.step(game.world, float(game.world.balance.passage_seconds))
	game.hud.refresh(game.world, true)
	game.hud.show_section("Work")
	game.view.queue_redraw()
	await frames(3)
	await shot("passage_work_blocked")
