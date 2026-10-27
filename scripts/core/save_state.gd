extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const JsonSave = preload("res://addons/hatchery/storage/json_save.gd")
const World = preload("res://scripts/sim/world.gd")
const VECTOR_KEYS: Array[String] = ["pos", "anchor", "facing"]
const STATE_KEYS: Array[String] = ["materials", "food", "elapsed", "approach", "garden_progress", "garden_started", "garden_done", "harvest", "repair_reserved", "downs"]
var catalog: Dictionary
var store: RefCounted


func _init(data: Dictionary, path: String = "user://street.json") -> void:
	catalog = data
	store = JsonSave.new(path, 1, valid)
	store.schema_key = "schema_version"
	store.block_on_damage = true


func snapshot(world: RefCounted) -> Dictionary:
	var result: Dictionary = {"schema_version": 1, "properties": world.properties.duplicate(true), "player": _encode_actor(world.player), "survivors": [], "zombies": []}
	for key: String in STATE_KEYS:
		result[key] = world.get(key)
	for a: Dictionary in world.survivors:
		result.survivors.append(_encode_actor(a))
	for z: Dictionary in world.zombies:
		result.zombies.append(_encode_actor(z))
	return result


func _encode_actor(a: Dictionary) -> Dictionary:
	var result: Dictionary = a.duplicate(true)
	for key: String in VECTOR_KEYS:
		result[key] = [a[key].x, a[key].y]
	return result


func _decode_actor(a: Dictionary) -> Dictionary:
	var result: Dictionary = a.duplicate(true)
	for key: String in VECTOR_KEYS:
		result[key] = Vector2(float(a[key][0]), float(a[key][1]))
	return result


func restore(data: Dictionary) -> RefCounted:
	if not valid(data):
		return null
	var world := World.new(catalog)
	for key: String in STATE_KEYS:
		world.set(key, int(data[key]) if key in ["materials", "food", "downs"] else data[key])
	world.properties = data.properties.duplicate(true)
	world.player = _decode_actor(data.player)
	world.survivors.clear()
	world.zombies.clear()
	for a: Dictionary in data.survivors:
		world.survivors.append(_decode_actor(a))
	for z: Dictionary in data.zombies:
		world.zombies.append(_decode_actor(z))
	world.rebuild_routes()
	world.note("Street restored. Work, supplies and threats continue from this moment.")
	return world


func valid(data: Dictionary) -> bool:
	if not Rules.integer_in(data.get("schema_version"), 1, 1):
		return false
	for key: String in STATE_KEYS:
		if key in ["approach", "garden_started", "garden_done", "repair_reserved"]:
			if not data.get(key) is bool:
				return false
		elif not Rules.finite(data.get(key)) or float(data[key]) < 0:
			return false
	for key: String in ["materials", "food", "downs"]:
		if not Rules.whole(data[key]):
			return false
	if not data.get("properties") is Dictionary or data.properties.size() != 4:
		return false
	for p: Dictionary in catalog.properties:
		var state: Variant = data.properties.get(p.id)
		if not state is Dictionary:
			return false
		for key: String in ["claimed", "looted", "open"]:
			if not state.get(key) is bool:
				return false
		if not Rules.finite(state.get("gate_hp")) or float(state.gate_hp) < 0 or float(state.gate_hp) > float(catalog.balance.gate_health):
			return false
	if not data.properties.home.claimed or not _valid_actor(data.get("player"), float(catalog.balance.player_health)):
		return false
	if not data.get("survivors") is Array or not data.get("zombies") is Array:
		return false
	var ids: Array[String] = ["you"]
	for a: Variant in data.survivors + data.zombies:
		if not _valid_actor(a, maxf(float(catalog.balance.zombie_health), float(catalog.balance.survivor_health))) or ids.has(a.id):
			return false
		ids.append(a.id)
	for z: Variant in data.zombies:
		if not z.get("raid") is bool or not z.get("home") is String:
			return false
	if data.survivors.size() != (2 if data.properties.library.claimed else 1):
		return false
	if data.survivors[0].id != "mara" or (data.survivors.size() == 2 and data.survivors[1].id != "paige"):
		return false
	if float(data.garden_progress) > float(catalog.balance.work_seconds) or (data.garden_done and not data.garden_started):
		return false
	return true


func _valid_actor(a: Variant, max_health: float) -> bool:
	if not a is Dictionary:
		return false
	for key: String in ["id", "name", "activity"]:
		if not Rules.nonempty(a.get(key)):
			return false
	if a.get("order") not in ["Guard", "Follow", "Hold", "Engage", "Home", "Build"]:
		return false
	for key: String in VECTOR_KEYS:
		if not Rules.is_vec2(a.get(key)):
			return false
	if float(a.pos[0]) < 0 or float(a.pos[1]) < 0 or float(a.pos[0]) > float(catalog.bounds[0]) or float(a.pos[1]) > float(catalog.bounds[1]):
		return false
	for key: String in ["hp", "cooldown", "flash", "swing"]:
		if not Rules.finite(a.get(key)) or float(a[key]) < 0:
			return false
	return float(a.hp) <= max_health
