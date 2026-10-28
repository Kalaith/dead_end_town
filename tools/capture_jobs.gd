extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_restoration.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world = Checks.prepared()
	game.world.player.pos = Vector2(1080, 800)
	Restoration.approve(game.world, "workshop")
	game.world.working = false
	game.view.world = game.world
	game.view.queue_redraw()
	game.set_process(false)
	game.hud.refresh(game.world, true)
	game.command("team")
	var picker: OptionButton = game.hud.team_orders.rows.mara.picker
	for index: int in range(picker.item_count):
		if picker.get_item_metadata(index) == "builder":
			picker.select(index)
			picker.item_selected.emit(index)
	game.command("work")
	game.hud.construction_menu.rows["restore:workshop"].priority.set_pressed(true)
	if not game.world.orders.sites["restore:workshop"].priority or game.world.survivors[0].duty.role != "builder":
		push_error("Connected priority/duty controls did not update simulation commands")
		quit(1)
		return
	Jobs.step(game.world, 0.05)
	if game.world.survivors[0].order != "Workshop":
		push_error("Builder did not select the priority project")
		quit(1)
		return
	game.hud.refresh(game.world, true)
	await frames(3)
	await shot("work_priority")
	game.hud.show_section("Team")
	await frames(3)
	await shot("temporary_duty")
	for i: int in range(640):
		game.world.step(0.05)
	if not game.world.workshop.done or game.world.survivors[0].duty.role != "builder" or game.world.survivors[0].order != "Garden":
		push_error("Physical builder failed priority completion and automatic duty resumption")
		quit(1)
		return
	game.hud.refresh(game.world, true)
	game.view.queue_redraw()
	await frames(3)
	await shot("builder_next_project")
