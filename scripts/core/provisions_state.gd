extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "provisions")
	if not data.get("balance") is Dictionary:
		return
	for key: String in ["meal_seconds", "recovery_food", "food_yield"]:
		rules.number_between(data.balance, key, 1, 1000)
	for key: String in ["recovery_food", "food_yield"]:
		if not Rules.whole(data.balance.get(key)):
			errors.append("Food costs/yields must be whole portions.")
	rules.number_between(data.balance, "shortage_work_rate", 0.1, 1)
	if not data.get("properties") is Array:
		return
	for raw: Variant in data.properties:
		if raw is Dictionary and not Rules.integer_in(raw.get("food_cache"), 0, 100):
			errors.append("Each property needs a bounded food cache.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("provisions") is Dictionary:
		return false
	var s: Dictionary = data.provisions
	if not s.get("hungry") is bool or not s.get("warned") is bool or not Rules.finite(s.get("clock")):
		return false
	if float(s.clock) < 0 or float(s.clock) >= float(catalog.balance.meal_seconds) or (s.hungry and float(s.clock) != 0):
		return false
	return Rules.integer_in(s.get("harvested"), 0, 1000000000)
