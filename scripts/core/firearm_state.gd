extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "firearm")
	if not rules.object(data, "firearm"):
		return
	for key: String in ["range", "damage", "cooldown", "hit_radius", "craft_seconds"]:
		rules.number_between(data.firearm, key, 0.01, 2000)
	for key: String in ["gift_bullets", "material_cost", "batch_bullets", "material_reserve", "bullet_target"]:
		if not Rules.integer_in(data.firearm.get(key), 1, 100):
			errors.append("Firearm %s must be a bounded positive integer." % key)
	if data.firearm.get("gift_bullets") != 6:
		errors.append("Ellis must hand over exactly six bullets.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("firearms") is Dictionary:
		return false
	var s: Dictionary = data.firearms
	if not s.get("owned") is bool or not Rules.integer_in(s.get("bullets"), 0, 1000000000):
		return false
	if s.owned != data.properties.residence.looted or (not s.owned and int(s.bullets) > 0 and not data.properties.munitions.looted):
		return false
	for a: Dictionary in data.survivors:
		if Firearms.civilian(a) and a.order in ["Guard", "Home", "Engage", "Roadguard"]:
			return false
	return true
