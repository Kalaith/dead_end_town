extends RefCounted
const Production = preload("res://scripts/sim/production.gd")
const WorkOrderState = preload("res://scripts/core/work_order_state.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const FirearmState = preload("res://scripts/core/firearm_state.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Salvage = preload("res://scripts/sim/salvage.gd")
const SliceState = preload("res://scripts/core/slice_state.gd")
const SliceObjective = preload("res://scripts/sim/slice_objective.gd")
const ProvisionsState = preload("res://scripts/core/provisions_state.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")
const EquipmentState = preload("res://scripts/core/equipment_state.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const NeighbourhoodState = preload("res://scripts/core/neighbourhood_state.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const PressureState = preload("res://scripts/core/pressure_state.gd")
const RoadState = preload("res://scripts/core/road_state.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const JsonSave = preload("res://addons/hatchery/storage/json_save.gd")
const World = preload("res://scripts/sim/world.gd")
const Workshop = preload("res://scripts/sim/workshop.gd")
const SCHEMA: int = 14
## Saved world fields that are dictionaries and are copied, not shared.
const COPIED_KEYS: Array[String] = ["production", "orders", "workshop", "roadworks", "pressure", "passages", "equipment", "provisions", "slice_state", "timber", "firearms"]
const VECTOR_KEYS: Array[String] = ["pos", "anchor", "facing"]
const STATE_KEYS: Array[String] = ["materials", "food", "elapsed", "approach", "garden_progress", "garden_started", "garden_done", "harvest", "repair_reserved", "downs", "production", "orders", "workshop", "roadworks", "pressure", "passages", "equipment", "provisions", "slice_state", "timber", "firearms", "gate_repair_target"]
var catalog: Dictionary
var store: RefCounted


func _init(data: Dictionary, path: String = "user://street.json") -> void:
	catalog = data
	store = JsonSave.new(path, SCHEMA, valid)
	store.migrate = migrate
	store.schema_key = "schema_version"
	store.block_on_damage = true


func snapshot(world: RefCounted) -> Dictionary:
	var result: Dictionary = {"schema_version": SCHEMA, "roam_rng_state": str(world.roam_rng.state), "properties": world.properties.duplicate(true), "player": _encode_actor(world.player), "survivors": [], "zombies": []}
	for key: String in STATE_KEYS:
		result[key] = world.get(key).duplicate(true) if key in COPIED_KEYS else world.get(key)
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
	var data: Dictionary = migrate(raw) if Rules.integer_in(raw.get("schema_version"), 1, SCHEMA - 1) else raw
	if not valid(data):
		return null
	var world := World.new(catalog)
	for key: String in STATE_KEYS:
		world.set(key, int(data[key]) if key in ["materials", "food", "downs"] else (data[key].duplicate(true) if key in COPIED_KEYS else data[key]))
	world.production.target = int(data.production.target)
	world.production.material_reserve = int(data.production.material_reserve)
	world.orders.sequence = int(data.orders.sequence)
	for order: Dictionary in world.orders.sites.values():
		order.sequence = int(order.sequence)
		for bundle: String in ["inputs", "outputs"]:
			for stock: String in order[bundle]:
				order[bundle][stock] = int(order[bundle][stock])
	world.firearms.bullets = int(data.firearms.bullets)
	world.slice_state.downs = int(data.slice_state.downs)
	world.provisions.harvested = int(data.provisions.harvested)
	world.roam_rng.state = int(data.roam_rng_state)
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
	if not Rules.integer_in(data.get("schema_version"), SCHEMA, SCHEMA):
		return false
	if not data.get("roam_rng_state") is String or str(int(data.roam_rng_state)) != data.roam_rng_state:
		return false
	for key: String in STATE_KEYS:
		if key in ["production", "orders", "workshop", "roadworks", "pressure", "passages", "equipment", "provisions", "slice_state", "timber", "firearms"]:
			continue
		if key == "gate_repair_target":
			if data.get(key) not in ["home", "garden", "library", "garage", "residence", "munitions"]:
				return false
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
	if not data.get("properties") is Dictionary or data.properties.size() != catalog.properties.size():
		return false
	for p: Dictionary in catalog.properties:
		var state: Variant = data.properties.get(p.id)
		if not state is Dictionary:
			return false
		for key: String in ["claimed", "looted", "open"]:
			if not state.get(key) is bool:
				return false
		if state.claimed and not state.looted:
			return false
		if not Rules.finite(state.get("occupation")) or float(state.occupation) < 0 or float(state.occupation) >= float(catalog.balance.territory_fall_seconds):
			return false
		if not state.claimed and float(state.occupation) != 0:
			return false
		if not Rules.finite(state.get("gate_hp")) or float(state.gate_hp) < 0 or float(state.gate_hp) > float(catalog.balance.gate_health):
			return false
	if not data.properties.home.looted or not _valid_actor(data.get("player"), float(catalog.balance.player_health)):
		return false
	if not data.get("survivors") is Array or not data.get("zombies") is Array:
		return false
	var ids: Array[String] = ["you"]
	for a: Variant in data.survivors + data.zombies:
		if not _valid_actor(a, maxf(ZombieTypes.max_health(catalog), float(catalog.balance.survivor_health))) or ids.has(a.id):
			return false
		ids.append(a.id)
	for z: Variant in data.zombies:
		if not z.get("raid") is bool or not z.get("home") is String:
			return false
		if z.has("kind") and (not z.kind is String or not catalog.zombies.types.has(z.kind) or float(z.hp) > ZombieTypes.health(catalog, z.kind)):
			return false
	var expected: Array[String] = ["mara"]
	if data.properties.library.looted:
		expected.append("paige")
	if data.properties.residence.looted:
		expected.append("ellis")
	var actual: Array[String] = []
	for a: Dictionary in data.survivors:
		actual.append(a.id)
	expected.sort()
	actual.sort()
	if actual != expected:
		return false
	if float(data.garden_progress) > float(catalog.balance.work_seconds) or (data.garden_done and not data.garden_started):
		return false
	if data.garden_started and not data.properties.garden.looted:
		return false
	if data.garden_done and float(data.garden_progress) < float(catalog.balance.work_seconds):
		return false
	if (data.workshop.started and not data.properties.garage.looted) or (data.workshop.equipped and not data.properties.library.looted):
		return false
	for a: Dictionary in data.survivors:
		if not _valid_task(a, data):
			return false
	if not RoadState.valid(data, catalog):
		return false
	if data.player.id != "you":
		return false
	return WorkOrderState.valid(data, catalog) and FirearmState.valid(data, catalog) and PressureState.valid(data, catalog) and NeighbourhoodState.valid(data, catalog) and EquipmentState.valid(data) and ProvisionsState.valid(data, catalog) and SliceState.valid(data, catalog)


func _valid_actor(a: Variant, max_health: float) -> bool:
	if not a is Dictionary:
		return false
	if not a.get("job") is String:
		return false
	for key: String in ["id", "name", "activity"]:
		if not Rules.nonempty(a.get(key)):
			return false
	if a.get("order") not in ["Guard", "Follow", "Hold", "Engage", "Home", "Build", "Roadwork", "Roadguard", "Garden", "Workshop", "Passage", "Ammo"]:
		return false
	for key: String in VECTOR_KEYS:
		if not Rules.is_vec2(a.get(key)):
			return false
	if float(a.pos[0]) < 0 or float(a.pos[1]) < 0 or float(a.pos[0]) > float(catalog.bounds[0]) or float(a.pos[1]) > float(catalog.bounds[1]):
		return false
	for key: String in ["hp", "cooldown", "flash", "swing"]:
		if not Rules.finite(a.get(key)) or float(a[key]) < 0:
			return false
	if not Rules.finite(a.get("roam_angle")) or absf(float(a.roam_angle)) > PI:
		return false
	if not Rules.finite(a.get("roam_left")) or float(a.roam_left) < 0 or float(a.roam_left) > float(catalog.balance.roam_turn_max):
		return false
	return float(a.hp) <= max_health


func migrate(data: Dictionary) -> Dictionary:
	if not Rules.integer_in(data.get("schema_version"), 1, SCHEMA - 1):
		return {}
	var upgraded: Dictionary = data.duplicate(true)
	var version: int = int(upgraded.schema_version)
	if version == 13:
		return _upgrade_production(upgraded)
	if version == 12:
		return _upgrade_orders(upgraded)
	if version == 11:
		return _upgrade_firearms(upgraded)
	if version == 10:
		return _upgrade_slice(upgraded)
	if version == 9:
		return _upgrade_provisions(upgraded)
	if version == 8:
		return _upgrade_equipment(upgraded)
	if version == 7:
		return _upgrade_neighbourhood(upgraded)
	if version == 6:
		return _upgrade_roaming(upgraded)
	if version == 5:
		return _upgrade_territory(upgraded)
	if version == 1:
		upgraded.workshop = Workshop.initial()
		upgraded.mara_site = "garden"
	if version <= 2:
		upgraded.roadworks = Roadworks.initial(catalog)
		upgraded.road_job = ""
	if version == 4:
		return _upgrade_pressure(upgraded)
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
	return _upgrade_pressure(upgraded)


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
		"Ammo":
			return a.job == "munitions" and data.properties.munitions.looted
		"Garden":
			return a.job == "garden" and data.garden_started
		"Workshop":
			return a.job == "garage" and data.workshop.started
		"Build":
			return (a.job == "garden" and data.garden_started) or (a.job == "garage" and data.workshop.started)
		"Passage":
			return data.get("passages") is Dictionary and data.passages.has(a.job)
		"Roadwork":
			return data.get("roadworks") is Dictionary and data.roadworks.has(a.job)
	return a.job == ""


func _upgrade_pressure(data: Dictionary) -> Dictionary:
	if not data.get("zombies") is Array or not data.get("properties") is Dictionary or not data.get("approach") is bool or not Rules.finite(data.get("elapsed")):
		return {}
	# Preserve old residents and cleared yards. Only previously unclaimed yards gain occupants.
	var fresh := World.new(catalog)
	var ids: Array[String] = []
	for z: Variant in data.zombies:
		if not z is Dictionary or not z.get("id") is String:
			return {}
		ids.append(z.id)
	for z: Dictionary in fresh.zombies:
		if z.id.begins_with("resident_") and not ids.has(z.id):
			if not data.properties.get(z.home) is Dictionary or not data.properties[z.home].get("claimed") is bool:
				return {}
			if data.properties[z.home].claimed:
				z.hp = 0.0
			data.zombies.append(_encode_actor(z))
	data.pressure = Pressure.initial(catalog)
	data.pressure.wave = 1 if data.approach else 0
	# Loading old progress gives a preparation interval, never an immediate overdue wave.
	data.pressure.next = float(data.elapsed) + float(catalog.pressure.interval_seconds)
	data.schema_version = 5
	return _upgrade_territory(data)


func _upgrade_territory(data: Dictionary) -> Dictionary:
	if not data.get("properties") is Dictionary:
		return {}
	for p: Variant in data.properties.values():
		if not p is Dictionary:
			return {}
		p.occupation = 0.0
	data.schema_version = 6
	return _upgrade_roaming(data)


func _upgrade_roaming(data: Dictionary) -> Dictionary:
	if not data.get("player") is Dictionary or not data.get("survivors") is Array or not data.get("zombies") is Array:
		return {}
	for a: Variant in [data.player] + data.survivors + data.zombies:
		if not a is Dictionary:
			return {}
		a.roam_angle = 0.0
		a.roam_left = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(catalog.balance.roam_seed)
	data.roam_rng_state = str(rng.state)
	data.schema_version = 7
	return _upgrade_neighbourhood(data)


func _upgrade_neighbourhood(data: Dictionary) -> Dictionary:
	data.passages = Neighbourhood.initial(catalog)
	data.schema_version = 8
	return _upgrade_equipment(data)


func _upgrade_equipment(data: Dictionary) -> Dictionary:
	if not data.get("workshop") is Dictionary or not data.workshop.get("equipped") is bool:
		return {}
	data.equipment = Equipment.initial()
	if data.workshop.equipped:
		data.equipment.iron = "paige"
		data.equipment.shield = "paige"
	data.schema_version = 9
	return _upgrade_provisions(data)


func _upgrade_provisions(data: Dictionary) -> Dictionary:
	data.provisions = Provisions.initial()
	data.schema_version = 10
	return _upgrade_slice(data)


func _upgrade_slice(data: Dictionary) -> Dictionary:
	data.gate_repair_target = "home"
	data.timber = Salvage.initial()
	data.slice_state = SliceObjective.initial()
	data.schema_version = 11
	return _upgrade_firearms(data)


func _upgrade_firearms(data: Dictionary) -> Dictionary:
	if not data.get("properties") is Dictionary or not data.get("passages") is Dictionary or not data.get("zombies") is Array:
		return {}
	var fresh := World.new(catalog)
	for id: String in ["residence", "munitions"]:
		if data.properties.has(id):
			continue
		data.properties[id] = fresh.properties[id].duplicate(true)
		for z: Dictionary in fresh.zombies:
			if z.home == id:
				data.zombies.append(_encode_actor(z))
	for id: String in fresh.passages:
		if not data.passages.has(id):
			data.passages[id] = fresh.passages[id].duplicate(true)
	data.firearms = {"owned": false, "bullets": 0, "progress": 0.0, "reserved": false}
	data.schema_version = 12
	return _upgrade_orders(data)


func _upgrade_orders(data: Dictionary) -> Dictionary:
	if not data.get("firearms") is Dictionary:
		return {}
	var s: Dictionary = data.firearms
	if not s.get("reserved") is bool or not Rules.finite(s.get("progress")):
		return {}
	if float(s.progress) < 0 or float(s.progress) >= float(catalog.firearm.craft_seconds) or (float(s.progress) > 0 and not s.reserved):
		return {}
	data.orders = WorkOrders.initial()
	if s.reserved:
		var recipe: Dictionary = {"id": "bullets", "kind": "production", "inputs": {"materials": int(catalog.firearm.material_cost)}, "outputs": {"bullets": int(catalog.firearm.batch_bullets)}, "seconds": float(catalog.firearm.craft_seconds)}
		var site: Array = []
		for p: Dictionary in catalog.properties:
			if p.id == "munitions":
				site = p.site
		data.orders.sequence = 1
		data.orders.sites.munitions = WorkOrders.record(1, "munitions", "munitions", recipe, Vector2(float(site[0]), float(site[1])))
		data.orders.sites.munitions.work_done = float(s.progress)
	s.erase("reserved")
	s.erase("progress")
	data.schema_version = 13
	return _upgrade_production(data)


func _upgrade_production(data: Dictionary) -> Dictionary:
	data.production = Production.initial(catalog)
	if data.get("survivors") is Array:
		for a: Variant in data.survivors:
			if a is Dictionary and a.get("order") == "Ammo":
				data.production.mode = "repeat"
	data.schema_version = SCHEMA
	return data if valid(data) else {}
