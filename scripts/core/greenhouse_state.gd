extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Facility = preload("res://scripts/sim/facility.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "greenhouse")
	for key: String in ["greenhouse_cost", "greenhouse_yield"]:
		if not Rules.integer_in(data.balance.get(key), 1, 1000):
			errors.append("Greenhouse needs bounded whole cost and food yield.")
	for key: String in ["greenhouse_seconds", "greenhouse_food_seconds"]:
		rules.number_between(data.balance, key, 0.05, 1000)


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("properties") is Dictionary:
		return false
	var s: Variant = data.get("greenhouse")
	if not s is Dictionary or not s.get("started") is bool or not s.get("done") is bool:
		return false
	for pair: Array in [["progress", "greenhouse_seconds"], ["harvest", "greenhouse_food_seconds"]]:
		if not Rules.finite(s.get(pair[0])) or float(s[pair[0]]) < 0 or float(s[pair[0]]) > float(catalog.balance[pair[1]]):
			return false
	if s.started and not Facility.saved(data, catalog, "greenhouse").looted:
		return false
	if s.done and (not s.started or float(s.progress) != float(catalog.balance.greenhouse_seconds)):
		return false
	if not s.started and float(s.progress) != 0:
		return false
	if (not s.done and float(s.harvest) != 0) or float(s.harvest) >= float(catalog.balance.greenhouse_food_seconds):
		return false
	var growing: Variant = data.get("growing")
	if not growing is Dictionary or growing.size() != 2:
		return false
	for id: String in ["garden", "greenhouse"]:
		if not growing.get(id) is bool:
			return false
	return Rules.finite(data.get("harvest")) and float(data.harvest) >= 0 and float(data.harvest) < float(catalog.balance.food_seconds)
