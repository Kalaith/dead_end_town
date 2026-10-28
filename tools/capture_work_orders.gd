extends "res://addons/hatchery/testing/capture_runner.gd"
const World = preload("res://scripts/sim/world.gd")
const RoadChecks = preload("res://tools/checks/checks_road_orders.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const RestorationChecks = preload("res://tools/checks/checks_restoration.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Checks = preload("res://tools/checks/checks_passage_orders.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = World.new(game.world.catalog)
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	game.world.claim("garden")
	game.world.player.pos = Vector2(600, 400)
	game.world.materials = 6
	game.world.messages.clear()
	game.view.world = game.world
	game.view.queue_redraw()
	game.hud.refresh(game.world, false)
	await frames(3)
	await shot("field_supplies")
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

	game.hud.menu_status.text = ""
	game.world = RestorationChecks.prepared("workshop")
	Restoration.step(game.world, "workshop", 4.0)
	game.view.world = game.world
	game.view.queue_redraw()
	game.hud.refresh(game.world, true)
	game.hud.show_section("Work")
	await frames(3)
	await shot("restoration_work_board")
	stock = game.world.materials
	game.hud.construction_menu.rows["restore:workshop"].cancel.pressed.emit()
	if game.world.materials <= stock or game.world.workshop.started:
		push_error("Restoration cancellation did not reach the simulation")
		quit(1)
		return

	game.world = RoadChecks.prepared()
	Roadworks.step(game.world, 8.0)
	game.world.interact()
	Roadworks.step(game.world, 1.0)
	game.view.world = game.world
	game.view.queue_redraw()
	game.hud.refresh(game.world, true)
	game.hud.menu_status.text = ""
	game.hud.show_section("Work")
	await frames(3)
	await shot("road_removal_board")
	stock = game.world.materials
	game.hud.construction_menu.rows["road:home_east"].cancel.pressed.emit()
	if game.world.materials != stock or not Roadworks.active(game.world.roadworks.home_east):
		push_error("Keeping a barricade paid salvage or lost collision")
		quit(1)
		return
