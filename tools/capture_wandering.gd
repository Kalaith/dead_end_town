extends "res://addons/hatchery/testing/capture_runner.gd"
const World = preload("res://scripts/sim/world.gd")
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
	var starts: Array[Vector2] = []
	for i: int in range(4):
		var z: Dictionary = game.world.zombies[i]
		z.hp = 60.0
		z.pos = Vector2(950 + i * 80, 390)
		starts.append(z.pos)
	Territory.step(game.world, 8)
	game.paused = false
	await frames(3)
	await shot("wander_occupation")
	# Real windowed simulation advances the four occupiers from this lost yard.
	await seconds(6)
	var moved: int = 0
	for i: int in range(4):
		if game.world.zombies[i].pos.distance_to(starts[i]) > 20:
			moved += 1
	if moved < 3:
		push_error("Occupiers did not disperse during windowed simulation.")
		quit(1)
		return
	await shot("wander_dispersed")
	game.paused = true
	game.world = World.new(game.world.catalog)
	game.view.world = game.world
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	for a: Dictionary in game.world.survivors:
		a.hp = 0.0
		a.activity = "Down - rest at home to recover"
	game.world.player.pos = Vector2(500, 580)
	game.world.aim = Vector2.RIGHT
	for i: int in range(3):
		game.world.zombies[i].hp = 60.0
		game.world.zombies[i].pos = Vector2(550 + i * 10, 580 + (i - 1) * 20)
	game.world.attack()
	var hit: int = 0
	for z: Dictionary in game.world.zombies:
		if float(z.hp) == 30.0:
			hit += 1
	if hit != 1:
		push_error("A single bat swing damaged more than one shambler.")
		quit(1)
		return
	game.paused = false
	await frames(2)
	await shot("single_target_swing")
