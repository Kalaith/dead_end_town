extends "res://addons/hatchery/testing/capture_runner.gd"
const Territory = preload("res://scripts/sim/territory.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.command("resume")
	game.paused = true
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	game.world.claim("garden")
	game.world.player.pos = Vector2(720, 410)
	game.world.survivors[0].hp = 0.0
	game.world.survivors[0].activity = "Down - rest at home to recover"
	var z: Dictionary = game.world.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(1080, 380)
	Territory.step(game.world, 4)
	game.paused = false
	await frames(3)
	await shot("property_overrun")
	game.paused = true
	Territory.step(game.world, 4)
	if game.world.properties.garden.claimed:
		push_error("Occupation capture did not lose garden.")
		quit(1)
		return
	game.paused = false
	await frames(3)
	await shot("property_lost")
	game.paused = true
	z.hp = 0.0
	game.world.player.pos = Vector2(1080, 350)
	game.world.interact()
	if not game.world.properties.garden.claimed:
		push_error("Reclaim capture did not restore garden.")
		quit(1)
		return
	game.paused = false
	await frames(3)
	await shot("property_reclaimed")
