extends SceneTree
## Save check: snapshot/restore round trip, previous-schema upgrade and rejection of bad area records.
## Run: Godot --headless --path . --script res://tools/check_save.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	var saves := SaveState.new(data, "user://check_save.json")
	var world := World.new(data)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(world)))
	_expect("snapshot is the current schema", int(raw.schema_version) == SaveState.SCHEMA)
	_expect("snapshot names its area", raw.area == data.area.id and raw.frozen == {})
	var restored: RefCounted = saves.restore(raw.duplicate(true))
	_expect("round trip restores", restored != null and restored.area == data.area.id)
	var old: Dictionary = raw.duplicate(true)
	old.erase("area")
	old.erase("frozen")
	old.schema_version = 35
	var upgraded: RefCounted = saves.restore(old)
	_expect("schema 35 upgrades to the first area", upgraded != null and upgraded.frozen.is_empty())
	var wrong: Dictionary = raw.duplicate(true)
	wrong.area = "nowhere"
	_expect("unknown area is rejected", saves.restore(wrong) == null)
	var self_frozen: Dictionary = raw.duplicate(true)
	self_frozen.frozen = {data.area.id: {}}
	_expect("frozen copy of the current area is rejected", saves.restore(self_frozen) == null)
	quit(failures)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
