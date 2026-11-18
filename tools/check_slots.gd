extends SceneTree
## Save slots: paths, the one-line summary and independent saves. Run: Godot --headless --path . --script res://tools/check_slots.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const SaveSlots = preload("res://scripts/core/save_slots.gd")
const World = preload("res://scripts/sim/world.gd")
var failures: int = 0


func _init() -> void:
	_expect("slot 1 keeps the original file", SaveSlots.path(1) == "user://suburb.json")
	_expect("the other slots have their own files", SaveSlots.path(2) != SaveSlots.path(3) and SaveSlots.path(2) != SaveSlots.path(1))
	_expect("slots cycle 1 2 3 1", SaveSlots.next(1) == 2 and SaveSlots.next(3) == 1)
	var data: Dictionary = Catalog.read()
	var world := World.new(data)
	world.elapsed = 600.0
	var a := SaveState.new(data, "user://check_slot_a.json")
	var b := SaveState.new(data, "user://check_slot_b.json")
	_expect("an unused file reads as empty", SaveSlots.summary(2, "user://check_slot_missing.json") == "Slot 2 · empty")
	_expect("saving writes", a.store.save_data(a.snapshot(world)))
	_expect("the summary names the area and minutes", SaveSlots.summary(1, "user://check_slot_a.json") == "Slot 1 · suburb 10m")
	_expect("another file is untouched", SaveSlots.summary(3, "user://check_slot_b.json") == "Slot 3 · empty" and b.store.load_data().is_empty())
	_expect("a file reports the seconds it holds", is_equal_approx(SaveSlots.seconds("user://check_slot_a.json"), 600.0) and SaveSlots.seconds("user://check_slot_missing.json") == 0.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://check_slot_a.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://check_slot_a.json.bak"))
	_names_and_delete(data, world)
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


## Slot files in a folder of the check's own: a name shows on the button, Delete removes the save and its copies,
## and the chosen slot (2 or 3) is remembered.
func _names_and_delete(data: Dictionary, world: RefCounted) -> void:
	SaveSlots.root = "user://check_slots/"
	var save := SaveState.new(data, SaveSlots.path(2))
	_expect("a slot in the check folder saves", save.store.save_data(save.snapshot(world)) and save.store.save_data(save.snapshot(world)))
	_expect("a named slot shows its name", SaveSlots.summary(2, "", SaveSlots.clean_name("  Sunday run  ")) == "Slot 2 · Sunday run · suburb 10m")
	_expect("names are cut to fit", SaveSlots.clean_name("x".repeat(60)).length() == SaveSlots.NAME_LENGTH)
	_expect("deleting removes the save and its backup", SaveSlots.remove(2) and not FileAccess.file_exists(SaveSlots.path(2)) and not FileAccess.file_exists(SaveSlots.path(2) + ".bak"))
	_expect("the deleted slot reads as empty", SaveSlots.summary(2) == "Slot 2 · empty" and not SaveSlots.remove(2))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://check_slots/"))
	SaveSlots.root = "user://"
	var hud: Control = load("res://scripts/presentation/hud.gd").new()
	hud.settings.save_enabled = false
	_expect("slot 3 can be remembered", hud.settings.set_value("slot", 3) and hud.settings.set_value(SaveSlots.name_key(3), "Late game"))
	hud.free()


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
