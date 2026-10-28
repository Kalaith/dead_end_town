extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if not data.get("balance") is Dictionary:
		return
	var rules := Rules.new(errors, "field medicine")
	for key: String in ["field_medicine_cost", "field_heal"]:
		if not Rules.integer_in(data.balance.get(key), 1, 100):
			errors.append("Field medicine needs whole costs and healing.")
	for key: String in ["field_seconds", "field_range"]:
		rules.number_between(data.balance, key, 0.05, 1000)


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var s: Variant = data.get("field_care")
	if not s is Dictionary:
		return false
	var ids: Array[String] = ["you"]
	for a: Dictionary in data.survivors:
		ids.append(a.id)
	if not s.is_empty() and not data.properties.clinic.looted:
		return false
	for id: Variant in s:
		if id not in ids or not Rules.finite(s[id]) or float(s[id]) < 0 or float(s[id]) >= float(catalog.balance.field_seconds):
			return false
	return true
