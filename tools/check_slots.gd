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
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
