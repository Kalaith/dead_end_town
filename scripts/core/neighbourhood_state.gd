extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "neighbourhood")
	if data.get("balance") is Dictionary:
		for key: String in ["passage_cost", "passage_seconds", "passage_range", "passage_danger_range"]:
			rules.number_between(data.balance, key, 1, 1000)
		if not Rules.whole(data.balance.get("passage_cost")):
			errors.append("Passage cost must be whole materials.")
	for key: String in ["passages", "crossings"]:
		if not rules.list(data, key, false):
			continue
		var expected: Array = ["north", "south"] if key == "passages" else ["west", "east"]
		if rules.unique_ids(data[key]) != expected:
			errors.append("Missing authored neighbourhood links.")
		for raw: Variant in data[key]:
			if not raw is Dictionary:
				errors.append("Neighbourhood link must be an object.")
				continue
			var d: Dictionary = raw
			rules.text(d, "name")
			_rect(d.get("area"), errors)
			if rules.list(d, "requires", false):
				var pairs: Array = [["home", "garden"], ["library", "garage"]] if key == "passages" else [["home", "library"], ["garden", "garage"]]
				if not expected.has(d.get("id")) or d.requires != pairs[expected.find(d.get("id"))]:
					errors.append("Neighbourhood link has incorrect property endpoints.")
			if key == "passages":
				_rect(d.get("gate"), errors)
				if rules.list(d, "rails", false):
					if d.rails.size() != 2:
						errors.append("Passage needs two fence rails.")
					for rect: Variant in d.rails:
						_rect(rect, errors)
				if rules.list(d, "sites", false):
					if d.sites.size() != 2:
						errors.append("Passage needs work positions on both sides.")
					for site: Variant in d.sites:
						if not Rules.is_vec2(site):
							errors.append("Invalid passage work position.")
			elif rules.list(d, "barriers", false):
				var barriers: Array = ["home_west", "home_east"] if d.id == "west" else ["garden_west", "garden_east"]
				if d.barriers != barriers:
					errors.append("Crossing needs both physical end barricades.")


static func _rect(raw: Variant, errors: Array[String]) -> void:
	if not raw is Array or raw.size() != 4:
		errors.append("Neighbourhood rectangle needs four numbers.")
		return
	for n: Variant in raw:
		if not Rules.finite(n):
			errors.append("Invalid neighbourhood rectangle.")
			return
	if float(raw[2]) <= 0 or float(raw[3]) <= 0:
		errors.append("Neighbourhood rectangle needs positive dimensions.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("passages") is Dictionary or data.passages.size() != catalog.passages.size():
		return false
	for d: Dictionary in catalog.passages:
		var raw: Variant = data.passages.get(d.id)
		if not raw is Dictionary:
			return false
		var s: Dictionary = raw
		for key: String in ["started", "done", "open", "repair_reserved"]:
			if not s.get(key) is bool:
				return false
		if not Rules.finite(s.get("hp")) or not Rules.finite(s.get("progress")):
			return false
		if float(s.hp) < 0 or float(s.hp) > float(catalog.balance.gate_health) or float(s.progress) < 0 or float(s.progress) > float(catalog.balance.passage_seconds):
			return false
		if not s.started and (float(s.progress) != 0 or s.done):
			return false
		if not s.done and (float(s.hp) != 0 or s.open or s.repair_reserved):
			return false
		if s.done and (not s.started or float(s.progress) != float(catalog.balance.passage_seconds)):
			return false
		if s.started:
			for id: String in d.requires:
				if not data.properties[id].looted:
					return false
	for a: Dictionary in data.survivors:
		if a.order == "Passage" and (not data.passages.has(a.job) or not data.passages[a.job].started):
			return false
	return true
