extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "search")
	for p: Dictionary in data.properties:
		if not p.has("search"):
			continue
		if not p.available or not p.search is Dictionary:
			errors.append("Search rewards need an implemented site.")
			continue
		if not Rules.integer_in(p.search.get("materials"), 0, 1000):
			errors.append("Search materials must be a bounded whole amount.")
		if not Rules.integer_in(p.search.get("medicine"), 0, 1000):
			errors.append("Search medicine must be a bounded whole amount.")
		if p.search.get("survivor") != ("june" if p.id == "clinic" else "oliver" if p.id == "greenhouse" else ""):
			errors.append("Search needs its implemented rescue identity.")
		rules.text(p.search, "line")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	for p: Dictionary in catalog.properties:
		var s: Dictionary = data.properties[p.id]
		if not s.get("claimed_once") is bool:
			return false
		if (s.claimed or s.claimed_once) and not s.looted:
			return false
		if s.claimed and not s.claimed_once:
			return false
		if not p.has("search") and s.looted != s.claimed_once:
			return false
	return true
