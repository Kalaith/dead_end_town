extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_medicine.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.prepared()
	game.view.world = game.world
	game.camera.position = Vector2(3240, 400)
	game.camera.force_update_scroll()
	game.command("work")
	var menu: VBoxContainer = game.hud.medicine_menu
	menu.mode.select(1)
	menu.mode.item_selected.emit(1)
	if game.world.medicine_production.mode != "once" or game.world.materials != 20 or game.world.food != 20:
		push_error("Connected medicine policy spent supplies before physical work")
		quit(1)
		return
	Clinic.step(game.world, 15.0)
	game.hud.refresh(game.world, true)
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before:
		push_error("Paused planning advanced paid medicine work")
		quit(1)
		return
	await frames(3)
	await shot("medicine_work")
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("medicine_crafting")
	game.command("work")
	menu.cancel_button.pressed.emit()
	if game.world.materials != 19 or game.world.food != 19 or game.world.medicine != 0 or game.world.medicine_production.mode != "stopped":
		push_error("Connected medicine cancellation returned the wrong bundle")
		quit(1)
		return
	menu.target.value = 4
	menu.mode.select(2)
	menu.mode.item_selected.emit(2)
	Clinic.step(game.world, 30.0)
	Clinic.step(game.world, 30.0)
	Clinic.step(game.world, 30.0)
	if game.world.medicine != 4 or game.world.materials != 17 or game.world.food != 15:
		push_error("Connected medicine target did not stop after two batches")
		quit(1)
		return
	game.hud.refresh(game.world, true)
	await frames(3)
	await shot("medicine_target")
