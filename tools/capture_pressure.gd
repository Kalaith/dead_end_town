extends "res://addons/hatchery/testing/capture_runner.gd"
const World = preload("res://scripts/sim/world.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world.player.pos = Vector2(1080, 400)
	game.paused = false
	await seconds(0.4)
	game.paused = true
	await shot("occupied_garden")
	game.world = World.new(game.world.catalog)
	game.view.world = game.world
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		game.world.claim(id)
	game.world.player.pos = Vector2(720, 580)
	for index: int in [1, 2]:
		game.world.player.pos = game.world.routes.point(game.world.catalog.barricades[index].site)
		game.world.interact()
		game.world.working = true
		for i: int in range(162):
			game.world.step(0.05)
		game.world.working = false
	game.world.player.pos = Vector2(720, 580)
	game.world.pressure.wave = 4
	game.world.approach = true
	game.world.elapsed = float(game.world.pressure.next) - 11
	Pressure.step(game.world)
	game.command("resume")
	await seconds(0.5)
	await shot("raid_warning")
	game.paused = true
	game.world.elapsed = float(game.world.pressure.next)
	Pressure.step(game.world)
	# Keep the view at the junction while real edge spawns travel toward the line.
	game.world.pressure.next = game.world.elapsed + 1000
	for i: int in range(200):
		game.world.step(0.05)
	game.paused = false
	await frames(3)
	await shot("raid_crossfire")
