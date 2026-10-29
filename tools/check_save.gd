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
	var thin: Dictionary = _halved(raw, data)
	thin.schema_version = 38
	var grown: RefCounted = saves.restore(thin)
	_expect("a schema 38 save with half the residents is renumbered and refilled", grown != null and grown.zombies.size() == world.zombies.size())
	quit(failures)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1


## What a save from before the doubled yards looked like: the first half of each lot's starting zombies renumbered in
## order, and no extra reinforcements.
func _halved(raw: Dictionary, data: Dictionary) -> Dictionary:
	var result: Dictionary = raw.duplicate(true)
	var kept: Array = []
	var index: int = 0
	for p: Dictionary in data.properties:
		var old_count: int = p.zombies.size() / 2
		var seen: int = 0
		for z: Dictionary in result.zombies:
			if z.home == p.id and str(z.id).begins_with("z") and not z.raid:
				if seen < old_count:
					z.id = "z%d" % index
					index += 1
					kept.append(z)
				seen += 1
		var old_reinforcements: int = p.reinforcements.size() / 2
		for i: int in range(p.reinforcements.size()):
			for z: Dictionary in result.zombies:
				if z.id == "resident_%s_%d" % [p.id, i] and i < old_reinforcements:
					kept.append(z)
	for z: Dictionary in result.zombies:
		if z.home == "boss" or z.raid:
			kept.append(z)
	result.zombies = kept
	return result
