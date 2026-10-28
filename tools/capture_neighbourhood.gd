extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_neighbourhood.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.paused = true
	var w: RefCounted = game.world
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		w.claim(id)
	w.player.pos = Vector2(600, 400)
	w.interact()
	w.working = true
	for i: int in range(125):
		w.step(0.05)
	w.working = false
	w.interact()
	w.survivors[0].pos = Vector2(660, 400)
	w.survivors[0].order = "Hold"
	w.survivors[0].anchor = w.survivors[0].pos
	if not w.passages.north.done or not w.safe_connected("garden"):
		push_error("Passage capture failed to construct/open the physical route.")
		quit(1)
		return
	game.paused = false
	await frames(5)
	await shot("yard_passage")
	game.paused = true
	Checks.integrate(w)
	w.passages.north.open = false
	w.properties.garden.claimed = false
	w.rebuild_routes()
	game.command("team")
	await frames(5)
	await shot("neighbourhood_routes")
