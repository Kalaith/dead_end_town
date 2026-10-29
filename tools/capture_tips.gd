extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for tutorial tips: the first tip at the start, the gate tip after walking, and the pause Help tab.
## Run through tools/Capture.ps1 -Tour res://tools/capture_tips.gd.


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	town.command("resume")
	var world: RefCounted = town.world
	for z: Dictionary in world.zombies:
		z.hp = 0.0
	await seconds(0.6)
	await shot("tip_move")
	world.player.pos += Vector2(200, 0)
	await seconds(0.6)
	await shot("tip_gate_repair")
	town.command("menu")
	town.hud.show_section("Help")
	await seconds(0.4)
	await shot("tip_help_tab")
