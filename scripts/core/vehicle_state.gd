extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "Vehicle")
	if not rules.object(data, "vehicle"):
		return
	for key: String in ["hull", "forward", "reverse", "accel", "brake", "turn_degrees", "half_length", "half_width", "enter_range", "exit_clearance", "seats", "board_range", "repair_materials", "repair_seconds", "repair_hull"]:
		rules.number_between(data.vehicle, key, 0.1, 5000)
	if data.has("vehicle_bay"):
		var bay: Variant = data.vehicle_bay
		if not bay is Dictionary or not bay.get("position") is Array or bay.position.size() != 2 or not Rules.finite(bay.get("heading_degrees")):
			errors.append("Vehicle bay needs a position and heading.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var v: Variant = data.get("vehicle")
	if not v is Dictionary or not v.get("present") is bool or not v.get("driving") is bool:
		return false
	for key: String in ["x", "y", "heading", "speed", "hull"]:
		if not Rules.finite(v.get(key)):
			return false
	if not v.get("riders") is Array or not v.get("repair_paid") is bool or not Rules.finite(v.get("repair_progress")):
		return false
	if not v.present:
		return not v.driving and v.riders.is_empty() and not v.repair_paid and float(v.repair_progress) == 0.0
	var config: Dictionary = catalog.vehicle
	if float(v.hull) < 0 or float(v.hull) > float(config.hull) or float(v.speed) > float(config.forward) or float(v.speed) < -float(config.reverse):
		return false
	if float(v.x) < 0 or float(v.y) < 0 or float(v.x) > float(catalog.bounds[0]) or float(v.y) > float(catalog.bounds[1]):
		return false
	if float(v.repair_progress) < 0 or float(v.repair_progress) >= float(config.repair_seconds) or (float(v.repair_progress) > 0 and not v.repair_paid):
		return false
	if v.riders.size() > int(config.seats) or (not v.driving and not v.riders.is_empty()):
		return false
	var seen: Array[String] = []
	for id: Variant in v.riders:
		if not id is String or id in seen or not _living_survivor(data, id):
			return false
		seen.append(id)
	return not (v.driving and float(v.hull) <= 0)


static func _living_survivor(data: Dictionary, id: String) -> bool:
	for a: Variant in data.get("survivors", []):
		if a is Dictionary and a.get("id") == id:
			return float(a.get("hp", 0)) > 0
	return false
