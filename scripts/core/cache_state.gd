extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if not data.has("caches"):
		return
	var rules := Rules.new(errors, "caches")
	if not rules.list(data, "caches", false):
		return
	var ids: Array = rules.unique_ids(data.caches)
	for raw: Variant in data.caches:
		if not raw is Dictionary:
			continue
		rules.text(raw, "name")
		rules.text(raw, "line")
		for key: String in ["materials", "food", "medicine"]:
			if not Rules.integer_in(raw.get(key), 0, 100):
				errors.append("Cache %s needs bounded whole %s." % [raw.get("id"), key])
		if rules.vec2(raw, "pos") and data.get("bounds") is Array:
			var p: Vector2 = Routes.point(raw.pos)
			if p.x < 0 or p.y < 0 or p.x > float(data.bounds[0]) or p.y > float(data.bounds[1]):
				errors.append("Cache %s lies outside the map." % raw.get("id"))
	if ids.size() != data.caches.size():
		errors.append("Cache ids must be unique.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("caches_taken") is Array:
		return false
	var known: Array = catalog.get("caches", []).map(func(c: Dictionary) -> String: return str(c.id))
	var seen: Array = []
	for id: Variant in data.caches_taken:
		if not id is String or id not in known or id in seen:
			return false
		seen.append(id)
	return true
