extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const LEGACY: Array[String] = ["home", "garden", "library", "garage", "residence", "munitions"]
const OLD_ROADS: Array[String] = ["home_west", "home_east", "garden_west", "garden_east"]
const OLD_PASSAGES: Array[String] = ["north", "south", "far_north", "far_south"]


static func expand(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("properties") is Dictionary:
		return false
	for p: Dictionary in catalog.properties:
		if p.id not in LEGACY and not data.properties.has(p.id):
			data.properties[p.id] = {"claimed": false, "looted": false, "open": true, "occupation": 0.0, "gate_hp": float(catalog.balance.gate_health)}
	if data.get("roadworks") is Dictionary:
		for d: Dictionary in catalog.barricades:
			if d.id not in OLD_ROADS and not data.roadworks.has(d.id):
				data.roadworks[d.id] = Roadworks.empty()
	if data.get("passages") is Dictionary:
		var empty: Dictionary = Neighbourhood.initial(catalog)
		for id: String in empty:
			if id not in OLD_PASSAGES and not data.passages.has(id):
				data.passages[id] = empty[id]
	return true


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("seen") is Array or data.seen.size() > catalog.properties.size() or not data.seen.has("home"):
		return false
	var ids: Array[String] = []
	for p: Dictionary in catalog.properties:
		ids.append(p.id)
		if not p.available and (data.properties[p.id].claimed or data.properties[p.id].looted):
			return false
	var known: Array[String] = []
	for id: Variant in data.seen:
		if not id is String or id not in ids or id in known:
			return false
		known.append(id)
	return true
