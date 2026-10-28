extends RefCounted
const Jobs = preload("res://scripts/sim/jobs.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	for a: Dictionary in data.survivors:
		var duty: Variant = a.get("duty")
		if not duty is Dictionary or not duty.get("temporary") is bool:
			return false
		if not _task(duty.get("role"), a, data, catalog):
			return false
		if duty.temporary:
			if not _task(duty.get("return_task"), a, data, catalog, true):
				return false
		elif duty.get("return_task") != "":
			return false
		for key: String in ["anchor", "return_anchor"]:
			if not Rules.is_vec2(duty.get(key)):
				return false
		for pair: Array in [["retry", "work_retry_seconds"], ["clear_left", "work_clear_seconds"]]:
			if not Rules.finite(duty.get(pair[0])) or float(duty[pair[0]]) < 0 or float(duty[pair[0]]) > float(catalog.balance[pair[1]]):
				return false
	return true


static func _task(value: Variant, a: Dictionary, data: Dictionary, catalog: Dictionary, returning: bool = false) -> bool:
	if not value is String:
		return false
	if value in ["hold", "builder", "general"]:
		return true
	if value == "home":
		return a.id != "ellis"
	if returning and value in ["follow", "engage"]:
		return value != "engage" or a.id != "ellis"
	if value in ["garden", "garage", "ammo"]:
		return data.properties["munitions" if value == "ammo" else value].looted
	if value.begins_with("guard:") and a.id != "ellis":
		for d: Dictionary in catalog.barricades:
			if value == "guard:" + str(d.id):
				return true
	return false


static func migrate(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("survivors") is Array:
		return false
	for raw: Variant in data.survivors:
		if not raw is Dictionary or not Rules.is_vec2(raw.get("anchor")) or not raw.get("order") is String or not raw.get("job") is String or not raw.get("id") is String:
			return false
		var a: Dictionary = raw
		var actor: Dictionary = a.duplicate(true)
		actor.anchor = Routes.point(a.anchor)
		var task: String = Jobs.current(catalog, actor)
		var role: String = task if task in ["garden", "garage", "ammo", "builder", "general"] or task.begins_with("guard:") else "hold" if a.id == "ellis" else "home"
		Jobs.initialise(a, role)
		if a.order in ["Build", "Roadwork", "Passage", "Repair"]:
			a.duty.temporary = true
			a.duty.return_task = role
	return true
