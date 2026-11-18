extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for the pause menu's save slots: the slot button, a named slot, the overwrite prompt and the armed
## Delete. Slot files go to a folder of the tour's own (`SaveSlots.root`), so real saves are never touched.
## Run through tools/Capture.ps1 -Tour res://tools/capture_slots.gd.
const SaveSlots = preload("res://scripts/core/save_slots.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const ROOT: String = "user://capture_slots/"


func tour() -> void:
	SaveSlots.root = ROOT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	town.command("resume")
	town.command("menu")
	await seconds(0.4)
	town.command("slot")
	await seconds(0.4)
	await shot("pause_save_slots")
	# A longer run already in this slot: saving over it must ask first.
	var longer: Dictionary = town.save_state.snapshot(town.world)
	longer.elapsed = 5400.0
	var writer := SaveState.new(town.world.catalog, SaveSlots.path(town.slot))
	writer.store.save_data(longer)
	town.name_slot("Sunday run")
	town.command("save")
	await seconds(0.4)
	await shot("pause_overwrite_prompt")
	town.hud.slot_controls.delete_button.grab_focus()
	town.hud.slot_controls.delete_button.pressed.emit()
	await seconds(0.3)
	await shot("pause_delete_armed")
	for slot: int in range(1, SaveSlots.COUNT + 1):
		SaveSlots.remove(slot)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROOT))
