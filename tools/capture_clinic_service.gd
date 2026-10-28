extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_clinic.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")
const Roster = preload("res://scripts/sim/roster.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.connected_clinic(false)
	game.view.world = game.world
	game.camera.position = Vector2(3240, 400)
	game.camera.force_update_scroll()
	game.world.interact()
	game.command("work")
	var row: Dictionary = game.hud.construction_menu.rows["restore:clinic"]
	var picker: OptionButton = row.picker
	for index: int in range(picker.item_count):
		if picker.get_item_metadata(index) == "june":
			picker.select(index)
			picker.item_selected.emit(index)
	Clinic.step(game.world, 5.0)
	if game.world.clinic.progress != 5.0 or Roster.person(game.world, "june").order != "Clinic":
		push_error("Connected clinic work row failed to assign physical work")
		quit(1)
		return
	game.hud.refresh(game.world, true)
	await frames(3)
	await shot("clinic_work_board")
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("clinic_restoration")
	game.command("work")
	var materials: int = game.world.materials
	row.cancel.pressed.emit()
	if game.world.clinic.started or game.world.materials != materials + 11 or Roster.person(game.world, "june").order != "Hold":
		push_error("Connected clinic cancellation returned the wrong amount")
		quit(1)
		return
	game.world = Checks.connected_clinic()
	game.view.world = game.world
	var june: Dictionary = Roster.person(game.world, "june")
	june.hp = 0.0
	game.world.interact()
	game.world.release_interact()
	game.world.working = true
	Clinic.step(game.world, 5.0)
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before:
		push_error("Paused clinic advanced paid treatment")
		quit(1)
		return
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("clinic_treatment")
	var medicine: int = game.world.medicine
	Clinic.step(game.world, 5.0)
	if june.hp != 100 or not game.world.clinic.patients.is_empty() or game.world.medicine != medicine:
		push_error("Present clinic patient did not recover once")
		quit(1)
		return
