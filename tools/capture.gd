extends "res://addons/hatchery/testing/capture_runner.gd"
const World = preload("res://scripts/sim/world.gd")

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
	await _road_tour(game)


func _road_tour(game: Node) -> void:
	# A separate fixture stages defensive construction without touching a save.
	game.paused = true
	game.world = World.new(game.world.catalog)
	game.view.world = game.world
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	for id: String in ["library", "garden", "garage"]:
		game.world.claim(id)
	game.world.properties.home.open = true
	game.world.rebuild_routes()
	for index: int in [0, 1]:
		game.world.player.pos = game.world.routes.point(game.world.catalog.barricades[index].site)
		game.world.interact()
		game.world.working = true
		for i: int in range(162):
			game.world.step(0.05)
		game.world.working = false
		game.world.post_road_guard()
	game.world.player.pos = Vector2(360, 580)
	for i: int in range(160):
		game.world.step(0.05)
	game.paused = false
	await seconds(0.8)
	await shot("street_barricades")
	game.paused = true
	var attacker: Dictionary = game.world.zombies[0]
	attacker.hp = 60.0
	attacker.pos = Vector2(677, 580)
	attacker.raid = true
	game.world.step(0.05)
	game.paused = false
	await frames(2)
	await shot("street_attack")
	game.paused = true
	# Restore the presentation fixture for the independent salvage example.
	attacker.hp = 0.0
	game.world.roadworks.home_east.hp = float(game.world.balance.barricade_health)
	game.world.player.pos = Vector2(592, 580)
	game.world.interact()
	game.world.working = true
	for i: int in range(40):
		game.world.step(0.05)
	game.paused = false
	await seconds(0.4)
	await shot("street_salvage")
	game.paused = true
	game.world.working = true
	for i: int in range(42):
		game.world.step(0.05)
	game.world.player.pos = Vector2(1312, 580)
	game.world.interact()
	for i: int in range(162):
		game.world.step(0.05)
	game.world.working = false
	game.world.post_road_guard()
	game.world.player.pos = Vector2(1080, 580)
	for i: int in range(160):
		game.world.step(0.05)
	game.paused = false
	await seconds(0.8)
	await shot("street_frontier")
