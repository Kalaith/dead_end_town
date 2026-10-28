extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if not data.get("balance") is Dictionary:
		return
	var rules := Rules.new(errors, "medicine")
	for key: String in ["medicine_material_cost", "medicine_food_cost", "medicine_batch", "medicine_target"]:
		if not Rules.integer_in(data.balance.get(key), 1, 999):
			errors.append("Medicine needs whole bounded costs, batch and target.")
	rules.number_between(data.balance, "medicine_seconds", 0.05, 1000)


static func valid(data: Dictionary) -> bool:
	var p: Variant = data.get("medicine_production")
	if not p is Dictionary or p.get("mode") not in ["stopped", "once", "repeat"] or not Rules.integer_in(p.get("target"), 0, 999) or not p.get("reason") is String:
		return false
	return p.mode == "stopped" or data.clinic.done
