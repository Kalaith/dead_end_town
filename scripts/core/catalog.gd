extends RefCounted
## Authored content is validated before the simulation starts.
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
const FILES: Array[String] = ["street/work.json", "street/firearm.json", "street/balance.json", "street/pressure.json", "street/roads.json", "street/equipment.json", "street/properties.json", "zombies.json"]


static func read() -> Dictionary:
	var errors: Array[String] = []
	var data: Dictionary = {}
	for file: String in FILES:
		var part: Dictionary = JsonIO.read_object("res://data/" + file, errors, 1)
		for key: String in part:
			if key != "schema_version" and data.has(key):
				errors.append("%s repeats %s." % [file, key])
		data.merge(part)
	data.schema_version = 1
	errors.append_array(problems(data))
	for error: String in errors:
		push_error(error)
	return data if errors.is_empty() else {}


static func problems(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var rules := Rules.new(errors, "street")
	rules.schema_version(data, 1)
	rules.vec2(data, "bounds")
	if rules.object(data, "balance"):
		rules.number_between(data.balance, "attack_cone_dot", -1.0, 0.99)
		rules.number_between(data.balance, "home_gate_start_factor", 0.01, 1.0)
		rules.number_between(data.balance, "garage_bonus_materials", 0, 10000)
		rules.number_between(data.balance, "home_alert_radius", 1.0, 10000.0)
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
		for key: String in ["step", "player_speed", "survivor_speed", "player_health", "survivor_health", "melee_damage", "attack_reach", "attack_cooldown", "gate_health", "gate_damage", "gate_repair_cost", "gate_repair_rate", "claim_materials", "garden_cost", "work_seconds", "food_seconds", "approach_seconds", "territory_fall_seconds", "starting_materials", "starting_food", "workshop_cost", "workshop_seconds", "armour_cost", "armour_seconds"]:
			rules.number_between(data.balance, key, 0.001, 10000.0)
		for key: String in ["armour_damage_multiplier", "armour_speed_multiplier", "shield_damage_multiplier"]:
			rules.number_between(data.balance, key, 0.01, 1.0)
	_zombie_types(data, errors)
	if not rules.list(data, "properties", false):
		return errors
	var ids: Array = rules.unique_ids(data.properties)
	if ids != ["home", "garden", "library", "garage", "residence", "munitions"]:
		errors.append("The street needs home, garden, library, garage, residence and munitions in order.")
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
	PressureState.content(data, errors)
	RoadState.content(data, errors)
	NeighbourhoodState.content(data, errors)
	EquipmentState.content(data, errors)
	ProvisionsState.content(data, errors)
	FirearmState.content(data, errors)
	SliceState.content(data, errors)
	WorkRecipes.content(data, errors)
	return errors


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
