extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for the late additions: the van drawn and driven, a Spitter aiming and its pool, and the ending screen.
## Run through tools/Capture.ps1 -Tour res://tools/capture_late.gd.
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	var data: Dictionary = Catalog.read("office")
	town._enter(World.new(data), data)
	town.command("resume")
	var world: RefCounted = town.world
	for z: Dictionary in world.zombies:
		if z.get("kind") != "spitter":
			z.hp = 0.0
	world.player.hp = 100.0
	world.player.pos = Vehicle.pos(world) + Vector2(0, 60)
	await seconds(0.6)
	await shot("van_parked")
	world.interact()
	world.move_input = Vector2(0, -1)
	await seconds(1.0)
	await shot("van_driving")
	world.move_input = Vector2.ZERO
	await seconds(1.0)
	world.interact()
	for z: Dictionary in world.zombies:
		if z.get("kind") == "spitter":
			world.player.pos = z.pos + Vector2(220, 0)
	await seconds(1.0)
	await shot("spitter_aim")
	await seconds(1.6)
	await shot("spitter_pool")
	var works: Dictionary = Catalog.read("industrial")
	town._enter(World.new(works), works)
	town.command("resume")
	town.world.campaign_ended = true
	await seconds(0.6)
	await shot("ending_screen")
