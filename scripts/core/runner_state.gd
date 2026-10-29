extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Runner = preload("res://scripts/sim/runner.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if not data.get("zombies", {}).get("types", {}).get("runner") is Dictionary:
		errors.append("Runner kind is required.")
		return
	var rules := Rules.new(errors, "Runner")
	for type_id: String in data.zombies.types:
		if data.zombies.types[type_id] is Dictionary and data.zombies.types[type_id].has("lunge_range"):
			for key: String in ["lunge_range", "lunge_tell", "lunge_distance", "lunge_speed", "lunge_recovery", "lunge_cooldown"]:
				rules.number_between(data.zombies.types[type_id], key, 0.01, 1000.0)
	for property: Dictionary in data.properties:
		if not property.has("resident_kinds"):
			continue
		if not property.resident_kinds is Array or property.resident_kinds.size() != property.reinforcements.size():
			errors.append("Resident kinds must match reinforcement positions.")
			continue
		for kind: Variant in property.resident_kinds:
			if not kind is String or not data.zombies.types.has(kind):
				errors.append("Unknown resident kind.")


static func valid(z: Dictionary, catalog: Dictionary) -> bool:
	var config: Variant = catalog.zombies.types.get(z.get("kind", catalog.zombies.default))
	if not config is Dictionary or not config.has("lunge_range"):
		return not z.has("runner")
	if not z.get("runner") is Dictionary:
		return false
	var state: Dictionary = z.runner
	if state.get("phase") not in ["idle", "tell", "dash", "recover"]:
		return false
	for key: String in ["left", "distance", "retry", "dx", "dy"]:
		if not Rules.finite(state.get(key)):
			return false
	var direction := Vector2(float(state.dx), float(state.dy))
	if absf(direction.length() - 1.0) > 0.001 or float(state.retry) < 0 or float(state.retry) > float(config.lunge_cooldown):
		return false
	if float(state.distance) < 0 or float(state.distance) > float(config.lunge_distance) or float(state.left) < 0:
		return false
	if state.phase == "tell":
		return float(state.left) <= float(config.lunge_tell) and float(state.distance) == 0
	if state.phase == "recover":
		return float(state.left) <= float(config.lunge_recovery) and float(state.distance) == 0
	return float(state.left) == 0 and (state.phase == "dash" or float(state.distance) == 0)


## Upgrade living stand-ins in place, retaining IDs, positions and depleted residents.
static func migrate(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("zombies") is Array:
		return false
	var kinds: Dictionary = {}
	for property: Dictionary in catalog.properties:
		if property.has("resident_kinds"):
			for i: int in range(property.resident_kinds.size()):
				kinds["resident_%s_%d" % [property.id, i]] = property.resident_kinds[i]
	for z: Variant in data.zombies:
		if not z is Dictionary or not Rules.finite(z.get("hp")):
			return false
		if kinds.get(z.get("id")) == "runner" and not z.has("kind") and float(z.hp) > 0:
			z.kind = "runner"
			z.name = "Runner"
			z.hp = minf(float(z.hp), float(catalog.zombies.types.runner.health))
		if z.get("kind") == "runner" and not z.has("runner"):
			z.runner = Runner.initial()
	return true
