extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "Vehicle")
	if not rules.object(data, "vehicle"):
		return
	for key: String in ["hull", "forward", "reverse", "accel", "brake", "turn_degrees", "half_length", "half_width", "enter_range", "exit_clearance"]:
		rules.number_between(data.vehicle, key, 0.1, 5000)
	if data.has("vehicle_bay"):
		var bay: Variant = data.vehicle_bay
		if not bay is Dictionary or not bay.get("position") is Array or bay.position.size() != 2 or not Rules.finite(bay.get("heading_degrees")):
			errors.append("Vehicle bay needs a position and heading.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var v: Variant = data.get("vehicle")
	if not v is Dictionary or v.get("present") != catalog.has("vehicle_bay") or not v.get("driving") is bool:
		return false
	for key: String in ["x", "y", "heading", "speed", "hull"]:
		if not Rules.finite(v.get(key)):
			return false
	if not v.present:
		return not v.driving
	var config: Dictionary = catalog.vehicle
	if float(v.hull) < 0 or float(v.hull) > float(config.hull) or float(v.speed) > float(config.forward) or float(v.speed) < -float(config.reverse):
		return false
	if float(v.x) < 0 or float(v.y) < 0 or float(v.x) > float(catalog.bounds[0]) or float(v.y) > float(catalog.bounds[1]):
		return false
	return not (v.driving and float(v.hull) <= 0)
