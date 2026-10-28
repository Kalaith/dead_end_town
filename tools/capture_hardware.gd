extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_discoveries.gd")
const Exploration = preload("res://scripts/sim/exploration.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world.player.pos = Vector2(2520, 350)
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	game.camera.position = Vector2(2520, 400)
	game.camera.force_update_scroll()
	Exploration.update(game.world)
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("hardware_search")
	game.world.interact()
	if not game.world.properties.hardware.looted or game.world.properties.hardware.claimed:
		push_error("Hardware search did not stay separate from claim")
		quit(1)
		return
	game.world = Checks.prepared()
	game.view.world = game.world
	game.command("team")
	game.hud.show_section("Loadouts")
	game.hud.refresh(game.world, true)
	var picker: OptionButton = game.hud.equipment_menu.rows.you.weapon
	for index: int in range(picker.item_count):
		if picker.get_item_metadata(index) == "spear":
			picker.select(index)
			picker.item_selected.emit(index)
	if game.world.equipment.spear != "you":
		push_error("Connected loadout picker did not equip the recovered spear")
		quit(1)
		return
	await frames(3)
	await shot("spear_loadout")
	game.world.player.pos = Vector2(2400, 400)
	game.world.player.facing = Vector2.RIGHT
	game.camera.position = Vector2(2520, 400)
	game.camera.force_update_scroll()
	game.hud.message_seconds = 0.0
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("spear_street")
