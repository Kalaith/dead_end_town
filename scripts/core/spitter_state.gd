extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if not data.get("zombies", {}).get("types", {}).get("spitter") is Dictionary:
		errors.append("Spitter kind is required.")
		return
	var rules := Rules.new(errors, "Spitter")
	for key: String in ["notice_range", "spit_min", "spit_range", "spit_tell", "spit_retry", "spit_cooldown", "spit_speed", "spit_damage", "pool_radius", "pool_seconds", "pool_damage"]:
		rules.number_between(data.zombies.types.spitter, key, 0.01, 10000)
	if float(data.zombies.types.spitter.spit_min) >= float(data.zombies.types.spitter.spit_range):
		errors.append("Spitter minimum range must be below its maximum.")


## Globs in flight, pools and the shared pool cooldowns are saved so a reload does not clear the hazards.
static func hazards_valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("spits") is Array or not data.get("spit_hits") is Dictionary:
		return false
	var config: Dictionary = catalog.zombies.types.spitter
	for s: Variant in data.spits:
		if not s is Dictionary or s.get("t") not in ["glob", "pool"]:
			return false
		var keys: Array = ["x", "y", "tx", "ty"] if s.t == "glob" else ["x", "y", "age", "tick"]
		for key: String in keys:
			if not Rules.finite(s.get(key)):
				return false
		for key: String in ["x", "y"]:
			if float(s[key]) < 0 or float(s[key]) > float(catalog.bounds[0 if key == "x" else 1]):
				return false
		if s.t == "pool" and (float(s.age) < 0 or float(s.age) >= float(config.pool_seconds) or float(s.tick) < 1.0):
			return false
	for id: Variant in data.spit_hits:
		if not id is String or not Rules.finite(data.spit_hits[id]):
			return false
	return true


static func valid(z: Dictionary, catalog: Dictionary) -> bool:
	if z.get("kind") != "spitter":
		return not z.has("spitter")
	if not z.get("spitter") is Dictionary:
		return false
	var state: Dictionary = z.spitter
	var config: Dictionary = catalog.zombies.types.spitter
	if state.get("phase") not in ["idle", "aim"]:
		return false
	for key: String in ["left", "retry", "tx", "ty"]:
		if not Rules.finite(state.get(key)):
			return false
	if float(state.left) < 0 or float(state.retry) < 0 or float(state.retry) > float(config.spit_cooldown):
		return false
	if state.phase == "aim":
		return float(state.left) > 0 and float(state.left) <= float(config.spit_tell) and float(state.retry) == 0
	return float(state.left) == 0
