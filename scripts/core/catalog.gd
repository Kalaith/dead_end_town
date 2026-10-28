extends RefCounted
## Authored content is validated before the simulation starts.
const NeighbourhoodState = preload("res://scripts/core/neighbourhood_state.gd")
const PressureState = preload("res://scripts/core/pressure_state.gd")
const RoadState = preload("res://scripts/core/road_state.gd")
const JsonIO = preload("res://addons/hatchery/core/json_io.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")

static func read() -> Dictionary:
	var errors: Array[String] = []
	var data: Dictionary = JsonIO.read_object("res://data/street.json", errors, 1)
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
		rules.number_between(data.balance, "roam_seed", 1, 2147483647)
		rules.number_between(data.balance, "roam_turn_min", 0.05, 30)
		rules.number_between(data.balance, "roam_turn_max", 0.05, 30)
		if Rules.finite(data.balance.get("roam_turn_min")) and Rules.finite(data.balance.get("roam_turn_max")) and float(data.balance.roam_turn_min) > float(data.balance.roam_turn_max):
			errors.append("Wandering turn interval is reversed.")
		if not Rules.whole(data.balance.get("roam_seed")):
			errors.append("Wandering seed must be a whole number.")
		for key: String in ["step", "player_speed", "survivor_speed", "zombie_speed", "player_health", "survivor_health", "zombie_health", "melee_damage", "zombie_damage", "attack_reach", "attack_cooldown", "zombie_cooldown", "gate_health", "gate_damage", "gate_repair_cost", "gate_repair_rate", "claim_materials", "garden_cost", "work_seconds", "food_seconds", "approach_seconds", "territory_fall_seconds", "starting_materials", "starting_food", "workshop_cost", "workshop_seconds", "armour_cost", "armour_seconds"]:
			rules.number_between(data.balance, key, 0.001, 10000.0)
		for key: String in ["armour_damage_multiplier", "armour_speed_multiplier", "shield_damage_multiplier"]:
			rules.number_between(data.balance, key, 0.01, 1.0)
	if not rules.list(data, "properties", false):
		return errors
	var ids: Array = rules.unique_ids(data.properties)
	if ids != ["home", "garden", "library", "garage"]:
		errors.append("The first street needs home, garden, library and garage in order.")
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
		for key: String in ["zombies", "reinforcements"]:
			if not rules.list(p, key):
				continue
			for pos: Variant in p[key]:
				if not Rules.is_vec2(pos):
					errors.append("Invalid zombie position.")
	PressureState.content(data, errors)
	RoadState.content(data, errors)
	NeighbourhoodState.content(data, errors)
	return errors
