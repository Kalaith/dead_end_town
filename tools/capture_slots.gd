extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for the pause menu's save slot button. Run through tools/Capture.ps1 -Tour res://tools/capture_slots.gd.


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	town.command("resume")
	town.command("menu")
	await seconds(0.4)
	town.command("slot")
	await seconds(0.4)
	await shot("pause_save_slots")
