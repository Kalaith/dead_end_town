extends "res://addons/hatchery/testing/capture_runner.gd"


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.command("resume")
	game.paused = true
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	for a: Dictionary in game.world.survivors:
		a.hp = 0.0
		a.activity = "Down - rest at home to recover"
	game.world.player.pos = Vector2(500, 580)
	var z: Dictionary = game.world.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(700, 580)
	z.roam_angle = 0.0
	z.roam_left = 2.8
	game.paused = false
	await frames(2)
	await shot("pursuit_spotted")
	game.paused = false
	await seconds(2)
	if z.pos.x >= 630 or z.facing.x > -0.99:
		push_error("Nearby person did not override the zombie's opposite wander heading.")
		quit(1)
		return
	await shot("pursuit_approach")
