extends RefCounted
const ScreecherState = preload("res://scripts/core/screecher_state.gd")
const SpitterState = preload("res://scripts/core/spitter_state.gd")
const AttentionState = preload("res://scripts/core/attention_state.gd")
const RunnerState = preload("res://scripts/core/runner_state.gd")
const BossState = preload("res://scripts/core/boss_state.gd")
## Authored content is validated before the simulation starts.
const FieldMedicineState = preload("res://scripts/core/field_medicine_state.gd")
const MedicineState = preload("res://scripts/core/medicine_state.gd")
const RecoverySalvageState = preload("res://scripts/core/recovery_salvage_state.gd")
const RecoveryState = preload("res://scripts/core/recovery_state.gd")
const GreenhouseState = preload("res://scripts/core/greenhouse_state.gd")
const ClinicState = preload("res://scripts/core/clinic_state.gd")
const DiscoveryState = preload("res://scripts/core/discovery_state.gd")
const RosterState = preload("res://scripts/core/roster_state.gd")
const TownContent = preload("res://scripts/core/town_content.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const FirearmState = preload("res://scripts/core/firearm_state.gd")
const SliceState = preload("res://scripts/core/slice_state.gd")
const ProvisionsState = preload("res://scripts/core/provisions_state.gd")
const EquipmentState = preload("res://scripts/core/equipment_state.gd")
const NeighbourhoodState = preload("res://scripts/core/neighbourhood_state.gd")
const PressureState = preload("res://scripts/core/pressure_state.gd")
const RoadState = preload("res://scripts/core/road_state.gd")
const JsonIO = preload("res://addons/hatchery/core/json_io.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")

## Authored content is split by topic so no one file outgrows review. Add a file here when adding a topic.
## Shared files describe rules, people and equipment that travel between areas.
const SHARED_FILES: Array[String] = ["street/attention.json", "street/recovery.json", "street/survivors.json", "street/work.json", "street/firearm.json", "street/balance.json", "street/equipment.json", "zombies.json"]
## Area files describe one map; each lives under data/areas/<id>/ and area.json supplies its bounds and start points.
const AREA_FILES: Array[String] = ["area.json", "town.json", "pressure.json", "properties.json", "properties_additional.json", "roads.json", "passages.json"]
const APPENDED_KEYS: Array[String] = ["properties", "barricades", "crossings", "passages"]


## The registry of every area in campaign order; the first entry starts a new game.
static func registry(errors: Array[String] = []) -> Dictionary:
	return JsonIO.read_object("res://data/areas.json", errors, 1)


static func read(area_id: String = "") -> Dictionary:
	var errors: Array[String] = []
	var list: Dictionary = registry(errors)
	var data: Dictionary = {}
	if not errors.is_empty() or not list.get("areas") is Array or not list.get("first") is String:
		errors.append("Area registry needs a first area and a list of areas.")
	else:
		if area_id.is_empty():
			area_id = list.first
		var ids: Array = list.areas.map(func(entry: Dictionary) -> String: return str(entry.get("id")))
		if area_id not in ids:
			errors.append("Unknown area: " + area_id)
		else:
			for file: String in SHARED_FILES:
				_merge(data, JsonIO.read_object("res://data/" + file, errors, 1), file, errors)
			for file: String in AREA_FILES:
				_merge(data, JsonIO.read_object("res://data/areas/%s/%s" % [area_id, file], errors, 1), file, errors)
			data.areas = list.areas
	data.schema_version = 1
	errors.append_array(problems(data))
	for error: String in errors:
		push_error(error)
	return data if errors.is_empty() else {}


## Merges one file into the catalog. Lists of sites are appended; any other repeated value is an error.
static func _merge(data: Dictionary, part: Dictionary, file: String, errors: Array[String]) -> void:
	for key: String in part:
		if key == "schema_version":
			continue
		if not data.has(key):
			data[key] = part[key]
		elif data[key] is Array and part[key] is Array and key in APPENDED_KEYS:
			data[key].append_array(part[key])
		elif data[key] is Dictionary and part[key] is Dictionary:
			_merge(data[key], part[key], file, errors)
		else:
			errors.append("%s repeats %s." % [file, key])


static func problems(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var rules := Rules.new(errors, "street")
	rules.schema_version(data, 1)
	rules.vec2(data, "bounds")
	_area(data, rules, errors)
	if rules.object(data, "balance"):
		rules.number_between(data.balance, "attack_cone_dot", -1.0, 0.99)
		rules.number_between(data.balance, "home_gate_start_factor", 0.01, 1.0)
		rules.number_between(data.balance, "garage_bonus_materials", 0, 10000)
		rules.number_between(data.balance, "home_alert_radius", 1.0, 10000.0)
		rules.number_between(data.balance, "scout_range", 1.0, 10000.0)
		for key: String in ["player_start", "mara_start", "home_respawn", "home_alert_center"]:
			rules.vec2(data.balance, key)
		rules.number_between(data.balance, "zombie_notice_range", 29.0, 10000.0)
		rules.number_between(data.balance, "roam_seed", 1, 2147483647)
		rules.number_between(data.balance, "settle_percent", 0, 100)
		rules.number_between(data.balance, "roam_turn_min", 0.05, 30)
		rules.number_between(data.balance, "roam_turn_max", 0.05, 30)
		if Rules.finite(data.balance.get("roam_turn_min")) and Rules.finite(data.balance.get("roam_turn_max")) and float(data.balance.roam_turn_min) > float(data.balance.roam_turn_max):
			errors.append("Wandering turn interval is reversed.")
		if not Rules.whole(data.balance.get("roam_seed")):
			errors.append("Wandering seed must be a whole number.")
		for key: String in ["step", "work_retry_seconds", "work_clear_seconds", "food_target_buffer", "player_speed", "survivor_speed", "player_health", "survivor_health", "melee_damage", "attack_reach", "attack_cooldown", "gate_health", "gate_damage", "gate_repair_cost", "gate_repair_rate", "repair_seconds", "gate_rebuild_seconds", "legacy_repair_seconds", "claim_materials", "garden_cost", "work_seconds", "food_seconds", "approach_seconds", "territory_fall_seconds", "starting_materials", "starting_food", "workshop_cost", "workshop_seconds", "armour_cost", "armour_seconds"]:
			rules.number_between(data.balance, key, 0.001, 10000.0)
		for key: String in ["armour_damage_multiplier", "armour_speed_multiplier", "shield_damage_multiplier"]:
			rules.number_between(data.balance, key, 0.01, 1.0)
	if data.get("balance") is Dictionary:
		var b: Dictionary = data.balance
		if Rules.finite(b.get("legacy_repair_seconds")) and Rules.finite(b.get("gate_repair_rate")) and Rules.finite(b.get("gate_health")) and Rules.finite(b.get("barricade_health")):
			if float(b.legacy_repair_seconds) * float(b.gate_repair_rate) < maxf(float(b.gate_health), float(b.barricade_health)):
				errors.append("Legacy repair capacity must preserve a prepaid full repair.")
	_zombie_types(data, errors)
	RunnerState.content(data, errors)
	BossState.content(data, errors)
	AttentionState.content(data, errors)
	ScreecherState.content(data, errors)
	SpitterState.content(data, errors)
	if not rules.list(data, "properties", false):
		return errors
	var ids: Array = rules.unique_ids(data.properties)

	for raw: Variant in data.properties:
		if not raw is Dictionary:
			errors.append("Property must be an object.")
			continue
		var p: Dictionary = raw
		rules.text(p, "name")
		rules.text(p, "reward")
		for key: String in ["gate", "site", "post"]:
			rules.vec2(p, key)
		for key: String in ["rect", "building"]:
			if not p.get(key) is Array or p[key].size() != 4:
				errors.append("Property %s needs a four-number %s." % [p.get("id"), key])
			else:
				for n: Variant in p[key]:
					if not Rules.finite(n):
						errors.append("Invalid rectangle number.")
		if rules.list(p, "neighbors"):
			for neighbor: Variant in p.neighbors:
				if not ids.has(neighbor):
					errors.append("Unknown property neighbor.")
		if not Rules.finite(p.get("hidden_zombies")) or float(p.hidden_zombies) < 0 or float(p.hidden_zombies) != floorf(float(p.hidden_zombies)):
			errors.append("Property %s needs a whole hidden zombie quota." % p.get("id"))
		for key: String in ["zombies", "reinforcements"]:
			if not rules.list(p, key):
				continue
			for pos: Variant in p[key]:
				if not Rules.is_vec2(pos):
					errors.append("Invalid zombie position.")
	FieldMedicineState.content(data, errors)
	MedicineState.content(data, errors)
	RecoverySalvageState.content(data, errors)
	RecoveryState.content(data, errors)
	ClinicState.content(data, errors)
	GreenhouseState.content(data, errors)
	DiscoveryState.content(data, errors)
	RosterState.content(data, errors)
	TownContent.content(data, errors)
	PressureState.content(data, errors)
	RoadState.content(data, errors)
	NeighbourhoodState.content(data, errors)
	EquipmentState.content(data, errors)
	ProvisionsState.content(data, errors)
	FirearmState.content(data, errors)
	SliceState.content(data, errors)
	WorkRecipes.content(data, errors)
	return errors


static func _area(data: Dictionary, rules: RefCounted, errors: Array[String]) -> void:
	if not rules.object(data, "area") or not data.get("areas") is Array:
		return
	rules.text(data.area, "id")
	rules.text(data.area, "name")
	var ids: Array = rules.unique_ids(data.areas)
	if data.area.get("id") not in ids:
		errors.append("Area is not in the registry.")


static func _zombie_types(data: Dictionary, errors: Array[String]) -> void:
	var zombies: Variant = data.get("zombies")
	if not zombies is Dictionary or not zombies.get("types") is Dictionary or zombies.types.is_empty():
		errors.append("Zombie types must be a nonempty object.")
		return
	if not zombies.types.has(zombies.get("default")):
		errors.append("Default zombie type is not defined.")
	for id: String in zombies.types:
		var type_data: Variant = zombies.types[id]
		if not type_data is Dictionary:
			errors.append("Zombie type %s must be an object." % id)
			continue
		var rules := Rules.new(errors, "zombie " + id)
		rules.text(type_data, "name")
		for key: String in ["health", "speed", "damage", "cooldown", "breach"]:
			rules.number_between(type_data, key, 0.001, 10000.0)
