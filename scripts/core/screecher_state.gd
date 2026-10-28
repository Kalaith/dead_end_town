extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Screecher = preload("res://scripts/sim/screecher.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if not data.get("zombies", {}).get("types", {}).get("screecher") is Dictionary:
		errors.append("Screecher kind is required.")
		return
	var rules := Rules.new(errors, "Screecher")
	for key: String in ["call_tell", "call_retry", "call_cooldown", "call_pulse"]:
		rules.number_between(data.zombies.types.screecher, key, 0.01, 100)


static func valid(z: Dictionary, catalog: Dictionary) -> bool:
	if z.get("kind") != "screecher":
		return not z.has("screecher")
	if not z.get("screecher") is Dictionary:
		return false
	var state: Dictionary = z.screecher
	var config: Dictionary = catalog.zombies.types.screecher
	if state.get("phase") not in ["idle", "inhale"]:
		return false
	for key: String in ["left", "retry", "pulse"]:
		if not Rules.finite(state.get(key)) or float(state[key]) < 0:
			return false
	if float(state.retry) > maxf(float(config.call_retry), float(config.call_cooldown)) or float(state.pulse) > float(config.call_pulse):
		return false
	if state.phase == "inhale":
		return float(state.left) > 0 and float(state.left) <= float(config.call_tell) and float(state.retry) == 0
	return float(state.left) == 0


static func migrate(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("zombies") is Array:
		return false
	var config: Dictionary = catalog.zombies.types.screecher
	for z: Variant in data.zombies:
		if not z is Dictionary or not Rules.finite(z.get("hp")):
			return false
		if z.get("id") == "resident_clinic_0" and not z.has("kind") and float(z.hp) > 0:
			z.kind = "screecher"
			z.name = config.name
			# Preserve partial injury without increasing any saved health.
			z.hp = minf(float(z.hp), float(config.health))
		if z.get("kind") == "screecher" and not z.has("screecher"):
			z.screecher = Screecher.initial()
	return true
