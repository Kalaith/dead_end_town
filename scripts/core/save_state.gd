extends RefCounted
const RoadState = preload("res://scripts/core/road_state.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const JsonSave = preload("res://addons/hatchery/storage/json_save.gd")
const World = preload("res://scripts/sim/world.gd")
const Workshop = preload("res://scripts/sim/workshop.gd")
const VECTOR_KEYS: Array[String] = ["pos", "anchor", "facing"]
const STATE_KEYS: Array[String] = ["materials", "food", "elapsed", "approach", "garden_progress", "garden_started", "garden_done", "harvest", "repair_reserved", "downs", "workshop", "roadworks"]
var catalog: Dictionary
var store: RefCounted


func _init(data: Dictionary, path: String = "user://street.json") -> void:
	catalog = data
	store = JsonSave.new(path, 4, valid)
	store.migrate = migrate
	store.schema_key = "schema_version"
	store.block_on_damage = true


func snapshot(world: RefCounted) -> Dictionary:
	var result: Dictionary = {"schema_version": 4, "properties": world.properties.duplicate(true), "player": _encode_actor(world.player), "survivors": [], "zombies": []}
	for key: String in STATE_KEYS:
		result[key] = world.get(key).duplicate(true) if key in ["workshop", "roadworks"] else world.get(key)
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


func restore(raw: Dictionary) -> RefCounted:
	var data: Dictionary = migrate(raw) if raw.get("schema_version") in [1, 2, 3] else raw
	if not valid(data):
		return null
	var world := World.new(catalog)
	for key: String in STATE_KEYS:
		world.set(key, int(data[key]) if key in ["materials", "food", "downs"] else (data[key].duplicate(true) if key in ["workshop", "roadworks"] else data[key]))
	world.properties = data.properties.duplicate(true)
	world.player = _decode_actor(data.player)
	world.aim = world.player.facing
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
	if not Rules.integer_in(data.get("schema_version"), 4, 4):
		return false
	for key: String in STATE_KEYS:
		if key in ["workshop", "roadworks"]:
			continue
		if key in ["approach", "garden_started", "garden_done", "repair_reserved"]:
			if not data.get(key) is bool:
				return false
		elif not Rules.finite(data.get(key)) or float(data[key]) < 0:
			return false
	for key: String in ["materials", "food", "downs"]:
		if not Rules.whole(data[key]):
			return false
	if not _valid_workshop(data):
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
		if state.claimed != state.looted:
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
	if data.garden_started and not data.properties.garden.claimed:
		return false
	if data.garden_done and float(data.garden_progress) < float(catalog.balance.work_seconds):
		return false
	if (data.workshop.started and not data.properties.garage.claimed) or (data.workshop.equipped and not data.properties.library.claimed):
		return false
	for a: Dictionary in data.survivors:
		if not _valid_task(a, data):
			return false
	if not RoadState.valid(data, catalog):
		return false
	if data.player.id != "you":
		return false
	var expected_zombies: Dictionary = {}
	var index: int = 0
	for p: Dictionary in catalog.properties:
		for spawn: Array in p.zombies:
			expected_zombies["z%d" % index] = {"home": p.id, "raid": false}
			index += 1
	if data.approach:
		for i: int in range(3):
			expected_zombies["raid%d" % i] = {"home": "street", "raid": true}
	if data.zombies.size() != expected_zombies.size():
		return false
	for z: Dictionary in data.zombies:
		if not expected_zombies.has(z.id) or expected_zombies[z.id].home != z.home or expected_zombies[z.id].raid != z.raid:
			return false
	return true


func _valid_actor(a: Variant, max_health: float) -> bool:
	if not a is Dictionary:
		return false
	if not a.get("job") is String:
		return false
	for key: String in ["id", "name", "activity"]:
		if not Rules.nonempty(a.get(key)):
			return false
	if a.get("order") not in ["Guard", "Follow", "Hold", "Engage", "Home", "Build", "Roadwork", "Roadguard", "Garden", "Workshop"]:
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


func migrate(data: Dictionary) -> Dictionary:
	if not Rules.integer_in(data.get("schema_version"), 1, 3):
		return {}
	var upgraded: Dictionary = data.duplicate(true)
	var version: int = int(upgraded.schema_version)
	if version == 1:
		upgraded.workshop = Workshop.initial()
		upgraded.mara_site = "garden"
	if version <= 2:
		upgraded.roadworks = Roadworks.initial(catalog)
		upgraded.road_job = ""
	if upgraded.get("mara_site") not in ["garden", "garage"] or not upgraded.get("road_job") is String:
		return {}
	if not upgraded.get("player") is Dictionary or not upgraded.get("survivors") is Array or not upgraded.get("zombies") is Array:
		return {}
	for a: Variant in [upgraded.player] + upgraded.survivors + upgraded.zombies:
		if not a is Dictionary:
			return {}
		a.job = ""
		if a.get("order") == "Build":
			a.job = upgraded.mara_site
		elif a.get("order") == "Roadwork":
			a.job = upgraded.road_job
	upgraded.erase("mara_site")
	upgraded.erase("road_job")
	upgraded.schema_version = 4
	return upgraded if valid(upgraded) else {}


func _valid_workshop(data: Dictionary) -> bool:
	if not data.get("workshop") is Dictionary:
		return false
	var state: Dictionary = data.workshop
	for key: String in ["started", "done", "armour_started", "armour_done", "equipped"]:
		if not state.get(key) is bool:
			return false
	for entry: Array in [["progress", "workshop_seconds", "started", "done"], ["armour_progress", "armour_seconds", "armour_started", "armour_done"]]:
		if not Rules.finite(state.get(entry[0])):
			return false
		var progress: float = float(state[entry[0]])
		var duration: float = float(catalog.balance[entry[1]])
		if progress < 0 or progress > duration or (progress > 0 and not state[entry[2]]):
			return false
		if state[entry[3]] and (not state[entry[2]] or progress < duration):
			return false
	if (state.armour_started and not state.done) or (state.equipped and not state.armour_done):
		return false
	return true


func _valid_task(a: Dictionary, data: Dictionary) -> bool:
	match a.order:
		"Garden":
			return a.job == "garden" and data.garden_started
		"Workshop":
			return a.job == "garage" and data.workshop.started
		"Build":
			return (a.job == "garden" and data.garden_started) or (a.job == "garage" and data.workshop.started)
		"Roadwork":
			return data.get("roadworks") is Dictionary and data.roadworks.has(a.job)
	return a.job == ""
