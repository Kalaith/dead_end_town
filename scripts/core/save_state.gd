extends RefCounted
const ScreecherState = preload("res://scripts/core/screecher_state.gd")
const VehicleState = preload("res://scripts/core/vehicle_state.gd")
const SpitterState = preload("res://scripts/core/spitter_state.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const AttentionState = preload("res://scripts/core/attention_state.gd")
const RunnerState = preload("res://scripts/core/runner_state.gd")
const BossState = preload("res://scripts/core/boss_state.gd")
const FieldMedicineState = preload("res://scripts/core/field_medicine_state.gd")
const CompanionRescueState = preload("res://scripts/core/companion_rescue_state.gd")
const MedicineState = preload("res://scripts/core/medicine_state.gd")
const RecoverySalvageState = preload("res://scripts/core/recovery_salvage_state.gd")
const RecoveryState = preload("res://scripts/core/recovery_state.gd")
const GreenhouseState = preload("res://scripts/core/greenhouse_state.gd")
const Greenhouse = preload("res://scripts/sim/greenhouse.gd")
const ClinicState = preload("res://scripts/core/clinic_state.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")
const DiscoveryState = preload("res://scripts/core/discovery_state.gd")
const RosterState = preload("res://scripts/core/roster_state.gd")
const TownState = preload("res://scripts/core/town_state.gd")
const JobState = preload("res://scripts/core/job_state.gd")
const WorkOrderState = preload("res://scripts/core/work_order_state.gd")
const FirearmState = preload("res://scripts/core/firearm_state.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const SliceState = preload("res://scripts/core/slice_state.gd")
const ProvisionsState = preload("res://scripts/core/provisions_state.gd")
const EquipmentState = preload("res://scripts/core/equipment_state.gd")
const NeighbourhoodState = preload("res://scripts/core/neighbourhood_state.gd")
const PressureState = preload("res://scripts/core/pressure_state.gd")
const RoadState = preload("res://scripts/core/road_state.gd")
const SaveMigrations = preload("res://scripts/core/save_migrations.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const JsonSave = preload("res://addons/hatchery/storage/json_save.gd")
const World = preload("res://scripts/sim/world.gd")
const Workshop = preload("res://scripts/sim/workshop.gd")
const SCHEMA: int = 42
## Saved world fields that are collections and are copied, not shared.
const COPIED_KEYS: Array[String] = ["noise", "memories", "growing", "greenhouse", "field_care", "rescue_jobs", "medicine_production", "recovery_salvage", "carry", "home_rest", "clinic", "seen", "production", "orders", "workshop", "roadworks", "pressure", "passages", "equipment", "provisions", "slice_state", "timber", "firearms", "unlocks", "vehicle"]
const VECTOR_KEYS: Array[String] = ["pos", "anchor", "facing"]
## Saved world fields that are single values, validated one by one.
const SCALAR_KEYS: Array[String] = ["defeat_pending", "rescue_intro", "medicine", "materials", "food", "elapsed", "approach", "garden_progress", "garden_started", "garden_done", "harvest", "repair_reserved", "downs", "gate_repair_target"]
const STATE_KEYS: Array[String] = COPIED_KEYS + SCALAR_KEYS
var catalog: Dictionary
var store: RefCounted
var migrations: RefCounted


func _init(data: Dictionary, path: String = "user://suburb.json") -> void:
	catalog = data
	store = JsonSave.new(path, SCHEMA, valid)
	migrations = SaveMigrations.new(data, self)
	store.migrate = migrate
	store.schema_key = "schema_version"
	store.block_on_damage = true


func snapshot(world: RefCounted) -> Dictionary:
	var result: Dictionary = {"schema_version": SCHEMA, "roam_rng_state": str(world.roam_rng.state), "properties": world.properties.duplicate(true), "player": encode_actor(world.player), "survivors": [], "zombies": [], "area": world.area, "frozen": world.frozen.duplicate(true), "spits": world.spits.duplicate(true), "spit_hits": world.spit_hits.duplicate()}
	for key: String in STATE_KEYS:
		result[key] = world.get(key).duplicate(true) if key in COPIED_KEYS else world.get(key)
	for a: Dictionary in world.survivors:
		result.survivors.append(encode_actor(a))
	for z: Dictionary in world.zombies:
		result.zombies.append(encode_actor(z))
	return result


func encode_actor(a: Dictionary) -> Dictionary:
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
		world.set(key, int(data[key]) if key in ["materials", "food", "medicine", "downs"] else (data[key].duplicate(true) if key in COPIED_KEYS else data[key]))
	world.production.target = int(data.production.target)
	world.pressure.wave = int(data.pressure.wave)
	world.pressure.band = int(data.pressure.band)
	world.pressure.origin_repeats = int(data.pressure.origin_repeats)
	world.noise.sequence = int(data.noise.sequence)
	for event: Dictionary in world.noise.events:
		event.id = int(event.id)
	world.medicine_production.target = int(data.medicine_production.target)
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
	world.frozen = data.frozen.duplicate(true)
	world.spits.assign(data.spits)
	world.spit_hits = data.spit_hits.duplicate()
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
	if not _valid_areas(data):
		return false
	for key: String in STATE_KEYS:
		if key in COPIED_KEYS:
			continue
		if key == "rescue_intro":
			if not data.get(key) is String:
				return false
			continue
		if key == "gate_repair_target":
			if not data.get("properties") is Dictionary or not data.properties.has(data.get(key)):
				return false
			continue
		if key in ["defeat_pending", "approach", "garden_started", "garden_done", "repair_reserved"]:
			if not data.get(key) is bool:
				return false
		elif not Rules.finite(data.get(key)) or float(data[key]) < 0:
			return false
	for key: String in ["materials", "food", "medicine", "downs"]:
		if not Rules.whole(data[key]):
			return false
	if not GreenhouseState.valid(data, catalog):
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
		if not RunnerState.valid(z, catalog) or not ScreecherState.valid(z, catalog) or not SpitterState.valid(z, catalog):
			return false
		if not z.get("raid") is bool or not z.get("home") is String:
			return false
		if z.has("kind") and (not z.kind is String or not catalog.zombies.types.has(z.kind) or float(z.hp) > ZombieTypes.health(catalog, z.kind)):
			return false
	if not VehicleState.valid(data, catalog) or not SpitterState.hazards_valid(data, catalog):
		return false
	if not BossState.valid(data, catalog) or not AttentionState.valid(data, catalog):
		return false
	if not RosterState.valid(data, catalog) or not DiscoveryState.valid(data, catalog) or not ClinicState.valid(data, catalog) or not RecoveryState.valid(data, catalog) or not RecoverySalvageState.valid(data, catalog) or not MedicineState.valid(data) or not CompanionRescueState.valid(data, catalog) or not FieldMedicineState.valid(data, catalog):
		return false
	if float(data.garden_progress) > float(catalog.balance.work_seconds) or (data.garden_done and not data.garden_started):
		return false
	if data.garden_started and not Facility.saved(data, catalog, "garden").looted:
		return false
	if data.garden_done and float(data.garden_progress) < float(catalog.balance.work_seconds):
		return false
	if (data.workshop.started and not Facility.saved(data, catalog, "garage").looted) or (data.workshop.equipped and data.unlocks.is_empty() and not Facility.saved(data, catalog, "library").looted):
		return false
	for a: Dictionary in data.survivors:
		if not _valid_task(a, data):
			return false
	if not RoadState.valid(data, catalog):
		return false
	if data.player.id != "you":
		return false
	return TownState.valid(data, catalog) and JobState.valid(data, catalog) and WorkOrderState.valid(data, catalog) and FirearmState.valid(data, catalog) and PressureState.valid(data, catalog) and NeighbourhoodState.valid(data, catalog) and EquipmentState.valid(data, catalog) and ProvisionsState.valid(data, catalog) and SliceState.valid(data, catalog)


## The saved area must be the loaded one; other areas keep a frozen record of their own state.
func _valid_areas(data: Dictionary) -> bool:
	if data.get("area") != catalog.area.id or not data.get("frozen") is Dictionary:
		return false
	var ids: Array = catalog.areas.map(func(entry: Dictionary) -> String: return str(entry.id))
	for id: Variant in data.frozen:
		if id not in ids or id == data.area or not data.frozen[id] is Dictionary:
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
	if a.get("order") not in ["Guard", "Follow", "Hold", "Engage", "Home", "Build", "Roadwork", "Roadguard", "Garden", "Workshop", "Passage", "Ammo", "Idle", "Repair", "Clinic", "Greenhouse", "Rescue", "Field"]:
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
		"Repair":
			return data.properties.has(a.job) and data.properties[a.job].looted
		"Field":
			return a.job == "you" or data.survivors.any(func(person: Dictionary) -> bool: return person.id == a.job)
		"Rescue":
			return data.get("rescue_jobs") is Dictionary and data.rescue_jobs.has(a.id) and data.rescue_jobs[a.id] is Dictionary and a.job == data.rescue_jobs[a.id].get("patient")
		"Greenhouse":
			return a.job == "greenhouse" and data.greenhouse.started and Facility.saved(data, catalog, "greenhouse").looted
		"Clinic":
			return a.job == "clinic" and data.clinic.started and Facility.saved(data, catalog, "clinic").looted
		"Ammo":
			return a.job == "munitions" and Facility.saved(data, catalog, "munitions").looted
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


func migrate(data: Dictionary) -> Dictionary:
	return migrations.migrate(data)
