extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for the industrial works: the entrance, then the Foreman at its post beside the main gate.
## Run through tools/Capture.ps1 -Tour res://tools/capture_works.gd.
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	var data: Dictionary = Catalog.read("industrial")
	town._enter(World.new(data), data)
	town.command("resume")
	var entrance: Array = data.entrance.rect
	town.world.player.pos = Vector2(float(entrance[0]) + 160.0, float(entrance[1]) - 120.0)
	await seconds(0.6)
	await shot("works_entrance")
	var post: Array = data.boss.post
	town.world.player.pos = Vector2(float(post[0]) + 190.0, float(post[1]) + 30.0)
	await seconds(0.6)
	await shot("works_foreman")
	town.world.player.pos = Vector2(2760.0, 560.0)
	await seconds(0.6)
	await shot("works_home_street")
