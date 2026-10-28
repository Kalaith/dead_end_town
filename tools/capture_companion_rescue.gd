extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_companion_rescue.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.prepared()
	game.view.world = game.world
	game.command("team")
	var picker: OptionButton = game.hud.team_orders.rows.paige.picker
	for index: int in range(picker.item_count):
		if picker.get_item_metadata(index) == "rescue:mara":
			picker.select(index)
			picker.item_selected.emit(index)
	if Equipment.person(game.world, "paige").order != "Rescue" or game.world.rescue_jobs.paige.patient != "mara":
		push_error("Connected Team selector did not start a companion rescue")
		quit(1)
		return
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before:
		push_error("Paused Team page advanced the rescue")
		quit(1)
		return
	await frames(3)
	await shot("companion_rescue_order")
	for i: int in range(145):
		game.world.step(0.05)
	if game.world.rescue_jobs.paige.phase != "carry":
		push_error("Companion failed the physical approach and lift")
		quit(1)
		return
	var carrier: Dictionary = Equipment.person(game.world, "paige")
	# Stage the camera on the companion; movement remains the authoritative simulation.
	game.camera.position = Vector2(maxf(640, carrier.pos.x), clampf(carrier.pos.y - 40, 360, 800))
	game.camera.force_update_scroll()
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.hud.context_label.visible = false
	game.view.queue_redraw()
	await frames(3)
	await shot("companion_carried")
	for i: int in range(400):
		game.world.step(0.05)
	if not game.world.rescue_jobs.is_empty() or game.world.survivors[0].pos.distance_to(Vector2(360, 350)) > 30 or carrier.order != "Garden" or carrier.duty.temporary:
		push_error("Rescuer failed drop-off or previous duty resumption")
		quit(1)
		return
	game.hud.refresh(game.world, true)
	game.hud.show_section("Team")
	await frames(3)
	await shot("companion_rescue_return")
