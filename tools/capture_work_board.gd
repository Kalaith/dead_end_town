extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_restoration.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Exploration = preload("res://scripts/sim/exploration.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.prepared("workshop")
	game.world.working = false
	game.world.player.pos = Vector2(1080, 350)
	Restoration.approve(game.world, "garden")
	game.world.player.pos = Vector2(1080, 800)
	game.world.assign_survivor("mara", "garden")
	Exploration.update(game.world)
	game.view.world = game.world
	game.command("work")
	var row: Dictionary = game.hud.construction_menu.rows["restore:workshop"]
	var picker: OptionButton = row.picker
	picker.select(1)
	picker.item_selected.emit(1)
	if not game.world.survivors[0].duty.temporary or game.world.survivors[0].duty.return_task != "garden" or game.world.survivors[0].order != "Workshop":
		push_error("Connected board assignment erased regular duty")
		quit(1)
		return
	await frames(3)
	await shot("work_assignment")
	var before: Dictionary = game.save_state.snapshot(game.world)
	row.show.pressed.emit()
	if game.hud.section != "Town" or game.hud.town_map.selected != "garage" or game.save_state.snapshot(game.world) != before:
		push_error("Connected Show failed to locate work without world mutation")
		quit(1)
		return
	await frames(3)
	await shot("work_location")
