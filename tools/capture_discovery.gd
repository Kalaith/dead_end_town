extends "res://addons/hatchery/testing/capture_runner.gd"


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world.pressure.next = 1000.0
	await frames(2)
	if not _hidden(game):
		return
	game.world.player.pos = Vector2(360, 800)
	game.command("resume")
	await seconds(0.3)
	if not _hidden(game):
		return
	await shot("library_unsearched")
	game.paused = true
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	# Even a cleared library should not preview its survivor before the search.
	if game.world.context() != "E / Search and secure property":
		push_error("Unsearched property disclosed its reward.")
		quit(1)
		return
	game.world.claim("garden")
	game.world.claim("garage")
	game.world.player.pos = Vector2(1080, 800)
	game.world.interact()
	game.world.working = true
	for i: int in range(322):
		game.world.step(0.05)
	game.world.interact()
	for i: int in range(362):
		game.world.step(0.05)
	game.world.working = false
	game.world.interact()
	game.hud.show_menu()
	game.hud.refresh(game.world, true)
	if not game.world.workshop.armour_done or not _hidden(game):
		push_error("Equipment-before-rescue fixture failed.")
		quit(1)
		return
	await shot("armour_before_rescue")
	game.world.player.pos = Vector2(360, 800)
	game.world.interact()
	game.command("resume")
	await seconds(0.4)
	if game.world.survivors.size() != 2 or not game.world.messages.back().contains("Paige rescued"):
		push_error("Search failed to reveal and recruit Paige.")
		quit(1)
		return
	await shot("library_rescue")


func _hidden(game: Node) -> bool:
	var texts: Array[String] = [game.world.context(), game.hud.objective.text]
	texts.append_array(game.world.messages)
	for label: Node in game.hud.find_children("*", "Label", true, false):
		texts.append(label.text)
	for text: String in texts:
		if text.to_lower().contains("paige"):
			push_error("Paige revealed before rescue: " + text)
			quit(1)
			return false
	return true
