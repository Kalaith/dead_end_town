extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_equipment.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world = Checks.prepared()
	game.view.world = game.world
	game.paused = true
	game.hud.refresh(game.world, true)
	# Exercise the actual connected selectors, including three independent slots.
	for choice: Array in [["you", "weapon", "sword"], ["mara", "protection", "iron"], ["mara", "shield", "shield"], ["paige", "weapon", "crowbar"]]:
		var picker: OptionButton = game.hud.equipment_menu.rows[choice[0]][choice[1]]
		for index: int in range(picker.item_count):
			if picker.get_item_metadata(index) == choice[2]:
				picker.item_selected.emit(index)
	if game.world.equipment.sword != "you" or game.world.equipment.iron != "mara" or game.world.equipment.shield != "mara" or game.world.equipment.crowbar != "paige":
		push_error("Loadout UI did not issue unique ownership commands.")
		quit(1)
		return
	game.command("team")
	await frames(3)
	game.hud.show_section("Loadouts")
	game.hud.menu.get_child(0).scroll_vertical = 0
	await frames(5)
	await shot("equipment_choices")
	game.world.survivors[0].pos = Vector2(1030, 790)
	game.world.survivors[1].pos = Vector2(1130, 790)
	for a: Dictionary in game.world.survivors:
		a.order = "Hold"
		a.anchor = a.pos
	game.command("resume")
	await seconds(0.5)
	await shot("shared_equipment")
