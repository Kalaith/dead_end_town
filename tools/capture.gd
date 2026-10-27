extends "res://addons/hatchery/testing/capture_runner.gd"

func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	await shot("opening")
	game.command("resume")
	# Show the normal quiet HUD after the opening message expires.
	await seconds(7.2)
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
	game.paused = true
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	game.world.claim("library")
	game.world.claim("garage")
	game.world.player.pos = Vector2(1080, 800)
	game.world.interact()
	game.world.working = true
	for i: int in range(100):
		game.world.step(0.05)
	game.paused = false
	await seconds(0.8)
	await shot("workshop")
	game.paused = true
	game.world.working = true
	for i: int in range(240):
		game.world.step(0.05)
	game.world.interact()
	for i: int in range(370):
		game.world.step(0.05)
	game.world.survivors[1].pos = Vector2(1110, 800)
	game.world.interact()
	game.world.working = false
	game.paused = false
	await seconds(0.8)
	await shot("armour")
	game.command("menu")
	await frames(3)
	await shot("planning")
