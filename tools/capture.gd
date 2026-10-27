extends "res://addons/hatchery/testing/capture_runner.gd"

func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	await shot("opening")
	game.command("resume")
	await frames(5)
	await shot("home")
	game.paused = true
	game.world.player.pos = Vector2(1080, 400)
	for z: Dictionary in game.world.zombies:
		if z.home == "garden":
			z.hp = 0.0
	game.world.claim("garden")
	game.world.player.pos = Vector2(1080, 350)
	game.world.interact()
	game.world.working = true
	for i: int in range(260):
		game.world.step(0.05)
	game.paused = false
	await seconds(0.8)
	await shot("garden")
