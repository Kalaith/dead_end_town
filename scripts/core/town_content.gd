extends RefCounted
## Validates the lot graph of one area. Layout comes from authored links and rectangles, never from a fixed grid.
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Facility = preload("res://scripts/sim/facility.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "town")
	if not rules.object(data, "town"):
		return
	if not rules.list(data.town, "core", false) or not rules.list(data.town, "links", false) or not rules.list(data.town, "streets", false):
		return
	if not data.town.get("bands") is Dictionary:
		errors.append("Town needs a band for every property.")
		return
	var ids: Array = rules.unique_ids(data.properties)
	if "home" not in ids:
		errors.append("Every area needs a home property.")
	_facilities(data, errors)
	var core_ids: Array[String] = []
	for id: Variant in data.town.core:
		if not id is String or id not in ids or id in core_ids:
			errors.append("Core IDs must be unique known properties.")
		else:
			core_ids.append(id)
	var links: Array = _links(data, ids, errors)
	if not errors.is_empty():
		return
	for p: Dictionary in data.properties:
		if not p.get("core") is bool or p.core != (p.id in core_ids) or not p.get("available") is bool:
			errors.append("Property needs its declared core/available flags.")
		if not Rules.integer_in(data.town.bands.get(p.id), 0, 3):
			errors.append("Property needs a pressure band from 0 to 3.")
		var expected: Array[String] = []
		for edge: Array in links:
			if edge.has(p.id):
				expected.append(edge[1] if edge[0] == p.id else edge[0])
		if p.neighbors.size() != expected.size():
			errors.append("Property neighbours must match the authored links.")
		for neighbor: Variant in p.neighbors:
			if neighbor not in expected:
				errors.append("Neighbour is not an authored link.")
		if not p.available and (p.food_cache != 0 or not p.zombies.is_empty() or not p.reinforcements.is_empty() or p.hidden_zombies != 0):
			errors.append("Development shells cannot promise unimplemented rewards or encounters.")
	if not errors.is_empty():
		return
	_core_route(data, links, core_ids, errors)
	_streets(data, errors)
	var real_edges: Array = []
	for d: Dictionary in data.passages + data.crossings:
		if d.requires not in links or d.requires in real_edges:
			errors.append("Town link is duplicated or not an authored link.")
		real_edges.append(d.requires)
	if real_edges.size() != links.size():
		errors.append("Every authored link needs exactly one passage or crossing.")


## Each lot declares one facility kind. A kind may appear in at most one lot, and `home` must be the lot with id home.
static func _facilities(data: Dictionary, errors: Array[String]) -> void:
	var seen: Array[String] = []
	for p: Dictionary in data.properties:
		var kind: Variant = p.get("facility")
		if not kind is String or (kind != Facility.HOUSE and kind not in Facility.KINDS):
			errors.append("Property %s needs a known facility kind." % p.get("id"))
		elif kind != Facility.HOUSE and kind in seen:
			errors.append("Facility %s appears in more than one lot." % kind)
		elif kind != Facility.HOUSE:
			seen.append(kind)
		if (kind == "home") != (p.get("id") == "home"):
			errors.append("The home facility belongs to the lot with id home.")
	if "home" not in seen:
		errors.append("Every area needs a home facility.")


static func _links(data: Dictionary, ids: Array, errors: Array[String]) -> Array:
	var links: Array = []
	for raw: Variant in data.town.links:
		if not raw is Array or raw.size() != 2 or raw[0] == raw[1] or raw[0] not in ids or raw[1] not in ids:
			errors.append("Town link needs two different known properties.")
			continue
		if [raw[0], raw[1]] in links or [raw[1], raw[0]] in links:
			errors.append("Town link is duplicated.")
		links.append([raw[0], raw[1]])
	return links


## Core sites must be reachable from home through core sites alone, so no optional site is a hidden bridge.
static func _core_route(data: Dictionary, links: Array, core_ids: Array[String], errors: Array[String]) -> void:
	if "home" not in core_ids:
		errors.append("Home must be a core property.")
		return
	var reached: Array[String] = ["home"]
	var cursor: int = 0
	while cursor < reached.size():
		for edge: Array in links:
			if edge.has(reached[cursor]):
				var other: String = edge[1] if edge[0] == reached[cursor] else edge[0]
				if other in core_ids and other not in reached:
					reached.append(other)
		cursor += 1
	if reached.size() != core_ids.size():
		errors.append("Core properties must connect to home without optional properties.")


static func _streets(data: Dictionary, errors: Array[String]) -> void:
	for raw: Variant in data.town.streets:
		var rect: Variant = raw.get("rect") if raw is Dictionary else null
		if not rect is Array or rect.size() != 4 or raw.get("kind") not in ["road", "alley", "plaza"]:
			errors.append("Street needs a rectangle and a road, alley or plaza kind.")
			continue
		for n: Variant in rect:
			if not Rules.finite(n):
				errors.append("Invalid street rectangle number.")
		if errors.is_empty() and (float(rect[2]) <= 0 or float(rect[3]) <= 0):
			errors.append("Street rectangle must have positive dimensions.")


static func links(data: Dictionary) -> Array:
	return data.town.links
