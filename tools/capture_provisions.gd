extends "res://addons/hatchery/testing/capture_runner.gd"
const HomeRest = preload("res://scripts/sim/home_rest.gd")
const Checks = preload("res://tools/checks/checks_equipment.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world = Checks.prepared()
	game.view.world = game.world
	game.world.food = 0
	game.world.provisions.clock = 59.99
	Provisions.step(game.world, 0.05)
	game.command("team")
	await frames(5)
	await shot("food_shortage")
	game.world.food = 5
	Provisions.step(game.world, 0.05)
	game.world.player.pos = Vector2(360, 350)
	game.world.player.hp = 30.0
	game.world.interact()
	HomeRest.step(game.world, 15.0)
	if game.world.player.hp != 50 or game.world.food != 0:
		push_error("Recovery fixture did not spend a shared meal and recovery food.")
		quit(1)
		return
	game.command("resume")
	await seconds(0.3)
	await shot("food_recovery")
