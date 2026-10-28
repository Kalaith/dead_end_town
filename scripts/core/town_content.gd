extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "town")
	if not rules.object(data, "town"):
		return
	if not rules.list(data.town, "columns", false) or not rules.list(data.town, "core", false) or not rules.list(data.town, "districts", false):
		return
	if data.town.columns.size() != 12 or data.town.core.size() != 18 or data.town.districts.size() != 4:
		errors.append("Town needs twelve columns, eighteen core sites and four districts.")
	var ids: Array[String] = []
	for pair: Variant in data.town.columns:
		if not pair is Array or pair.size() != 2:
			errors.append("Town columns need a north/south pair.")
			continue
		for id: Variant in pair:
			if not id is String or ids.has(id):
				errors.append("Town property IDs must be unique.")
			else:
				ids.append(id)
	if not errors.is_empty():
		return
	var actual: Array = rules.unique_ids(data.properties)
	if actual.size() != 24 or actual.slice(0, 6) != ["home", "garden", "library", "garage", "residence", "munitions"]:
		errors.append("Preserve the six original property identities before new districts.")
	for id: String in ids:
		if not actual.has(id):
			errors.append("Missing town property: " + id)
	var core_ids: Array[String] = []
	for id: Variant in data.town.core:
		if not id is String or id not in ids or id in core_ids:
			errors.append("Core IDs must be unique known properties.")
		else:
			core_ids.append(id)
	var links: Array = []
	for c: int in range(data.town.columns.size()):
		var pair: Array = data.town.columns[c]
		if not data.town.core.has(pair[0]):
			errors.append("The northern core route cannot require optional property.")
		links.append([pair[0], pair[1]])
		if c > 0:
			for row: int in range(2):
				links.append([data.town.columns[c - 1][row], pair[row]])
	for p: Dictionary in data.properties:
		if not p.get("core") is bool or p.core != data.town.core.has(p.id) or not p.get("available") is bool:
			errors.append("Property needs its declared core/available flags.")
		var expected: Array[String] = []
		for edge: Array in links:
			if edge.has(p.id):
				expected.append(edge[1] if edge[0] == p.id else edge[0])
		if p.neighbors.size() != expected.size():
			errors.append("Town neighbours must follow the authored ladder.")
		for neighbor: Variant in p.neighbors:
			if neighbor not in expected:
				errors.append("Unknown/diagonal town neighbour.")
		if not p.available and (p.food_cache != 0 or not p.zombies.is_empty() or not p.reinforcements.is_empty() or p.hidden_zombies != 0):
			errors.append("Development shells cannot promise unimplemented rewards or encounters.")
	var real_edges: Array = []
	for d: Dictionary in data.passages + data.crossings:
		if d.requires not in links or d.requires in real_edges:
			errors.append("Town link is duplicated or not an authored ladder edge.")
		real_edges.append(d.requires)
	if real_edges.size() != 34:
		errors.append("Town needs all 34 property links.")


static func columns(data: Dictionary) -> Array:
	return data.town.columns
