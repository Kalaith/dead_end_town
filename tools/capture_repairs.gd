extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_repairs.gd")
const Repairs = preload("res://scripts/sim/repairs.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world = Checks.prepared()
	game.world.roadworks.home_east.hp = 90.0
	Repairs.step(game.world, "road:home_east", "you", 2.0)
	game.view.world = game.world
	game.view.queue_redraw()
	game.set_process(false)
	game.command("work")
	game.hud.refresh(game.world, true)
	await frames(3)
	await shot("repair_work_board")
	var stock: int = game.world.materials
	game.hud.construction_menu.rows["repair:road:home_east"].cancel.pressed.emit()
	if game.world.materials != stock + 1 or game.world.roadworks.home_east.repair_reserved:
		push_error("Repair cancellation lost or duplicated its remaining return")
		quit(1)
		return
	game.world.player.pos = Vector2(360, 440)
	game.world.properties.home.gate_hp = 0.0
	game.world.properties.home.open = false
	game.world.rebuild_routes()
	Repairs.step(game.world, "gate:home", "you", 3.0)
	game.hud.menu_status.text = ""
	game.hud.refresh(game.world, true)
	game.hud.show_section("Work")
	game.view.queue_redraw()
	await frames(3)
	await shot("gate_rebuild_work")
	Repairs.step(game.world, "gate:home", "you", 4.0)
	if game.world.properties.home.gate_hp != 160.0 or not game.world.properties.home.open:
		push_error("Rebuild failed to finish open")
		quit(1)
		return
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("gate_rebuilt")
