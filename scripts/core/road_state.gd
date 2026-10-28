extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "road defences")
	if data.get("balance") is Dictionary:
		for key: String in ["barricade_cost", "barricade_health", "barricade_seconds", "barricade_remove_seconds", "barricade_work_range", "barricade_danger_range", "barricade_repair_cost", "barricade_repair_rate", "barricade_attack_reach", "barricade_stand_offset"]:
			rules.number_between(data.balance, key, 1, 1000)
		for key: String in ["barricade_cost", "barricade_repair_cost"]:
			if not Rules.whole(data.balance.get(key)):
				errors.append("Road defence material costs must be whole numbers.")
		rules.number_between(data.balance, "barricade_salvage", 0, 1)
	if not rules.list(data, "barricades", false):
		return
	var expected: Array[String] = []
	if not data.get("town") is Dictionary:
		return
	for pair: Array in data.town.columns:
		expected.append(str(pair[0]) + "_west")
		expected.append(str(pair[0]) + "_east")
	if rules.unique_ids(data.barricades) != expected:
		errors.append("Every crossing needs its own west/east barrier pair.")
	for raw: Variant in data.barricades:
		if not raw is Dictionary:
			errors.append("Road defence must be an object.")
			continue
		var d: Dictionary = raw
		rules.text(d, "name")
		for key: String in ["center", "site"]:
			rules.vec2(d, key)
		var rect: Variant = d.get("rect")
		if not rect is Array or rect.size() != 4:
			errors.append("Road defence needs a four-number rectangle.")
		else:
			for n: Variant in rect:
				if not Rules.finite(n):
					errors.append("Invalid road defence rectangle.")
			if errors.is_empty() and (float(rect[2]) <= 0 or float(rect[3]) <= 0):
				errors.append("Road defence rectangle must have positive dimensions.")
		if rules.list(d, "requires", false):
			if d.requires not in data.town.columns:
				errors.append("Road defences require both facing properties.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("roadworks") is Dictionary or data.roadworks.size() != catalog.barricades.size():
		return false
	var ids: Array[String] = [""]
	for d: Dictionary in catalog.barricades:
		ids.append(d.id)
		var s: Variant = data.roadworks.get(d.id)
		if not s is Dictionary or s.get("phase") not in ["empty", "building", "ready", "dismantling"]:
			return false
		if not s.get("repair_reserved") is bool or not Rules.finite(s.get("hp")) or not Rules.finite(s.get("progress")):
			return false
		if float(s.hp) < 0 or float(s.hp) > float(catalog.balance.barricade_health) or float(s.progress) < 0:
			return false
		if s.phase == "empty" and (float(s.hp) != 0 or float(s.progress) != 0 or s.repair_reserved):
			return false
		if s.phase == "building" and (float(s.hp) != 0 or float(s.progress) > float(catalog.balance.barricade_seconds) or s.repair_reserved):
			return false
		if s.phase == "ready" and (float(s.hp) <= 0 or float(s.progress) != 0):
			return false
		if s.phase == "dismantling" and (float(s.hp) <= 0 or float(s.progress) > float(catalog.balance.barricade_remove_seconds) or s.repair_reserved):
			return false
		if s.phase != "empty":
			for id: String in d.requires:
				if not data.properties[id].looted:
					return false
	for a: Dictionary in data.survivors:
		if a.order == "Roadwork" and (a.job not in ids or a.job == "" or data.roadworks[a.job].phase == "empty"):
			return false
		if a.order == "Roadguard" and not _guard_has_post(a, data.roadworks, catalog):
			return false
	return true


static func _guard_has_post(actor: Dictionary, states: Dictionary, catalog: Dictionary) -> bool:
	var anchor := Vector2(float(actor.anchor[0]), float(actor.anchor[1]))
	for d: Dictionary in catalog.barricades:
		var center := Vector2(float(d.center[0]), float(d.center[1]))
		var site := Vector2(float(d.site[0]), float(d.site[1]))
		var post: Vector2 = center + center.direction_to(site) * float(catalog.balance.barricade_stand_offset)
		if states[d.id].phase in ["ready", "dismantling"] and anchor.distance_to(post) < 10:
			return true
	return false
