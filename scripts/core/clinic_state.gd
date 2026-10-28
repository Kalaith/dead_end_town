extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if not data.get("balance") is Dictionary:
		return
	var rules := Rules.new(errors, "clinic")
	for key: String in ["clinic_cost", "treatment_cost"]:
		if not Rules.integer_in(data.balance.get(key), 1, 1000):
			errors.append("Clinic costs need bounded whole inputs.")
	for key: String in ["clinic_seconds", "treatment_seconds"]:
		rules.number_between(data.balance, key, 0.05, 1000)


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var s: Variant = data.get("clinic")
	if not s is Dictionary or not s.get("started") is bool or not s.get("done") is bool or not s.get("patients") is Dictionary:
		return false
	if not Rules.finite(s.get("progress")) or float(s.progress) < 0 or float(s.progress) > float(catalog.balance.clinic_seconds):
		return false
	if s.started and not data.properties.clinic.looted:
		return false
	if s.done and (not s.started or float(s.progress) != float(catalog.balance.clinic_seconds)):
		return false
	if not s.started and (s.done or float(s.progress) != 0):
		return false
	if not s.patients.is_empty() and not s.done:
		return false
	var ids: Array[String] = ["you"]
	for a: Dictionary in data.survivors:
		ids.append(a.id)
	for id: Variant in s.patients:
		var paid: Variant = s.patients[id]
		if id not in ids or not paid is Dictionary or paid.size() != 1 or not Rules.finite(paid.get("progress")):
			return false
		if float(paid.progress) < 0 or float(paid.progress) >= float(catalog.balance.treatment_seconds):
			return false
	return true
