extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "street.pressure")
	if not rules.object(data, "pressure"):
		return
	var config: Dictionary = data.pressure
	for key: String in ["warning_seconds", "first_seconds", "first_claim_grace", "calm_seconds", "entry_seconds", "route_retry_seconds", "spawn_spacing"]:
		rules.number_between(config, key, 0.1, 1000)
	for key: String in ["maximum_size", "living_cap"]:
		if not Rules.integer_in(config.get(key), 1, 100):
			errors.append("Pressure needs a bounded whole " + key)
	if rules.object(config, "special_caps"):
		for kind: String in config.special_caps:
			if not data.zombies.types.has(kind) or not Rules.integer_in(config.special_caps[kind], 1, 96):
				errors.append("Pressure special cap needs an implemented kind and positive limit.")
	for kind: String in data.zombies.types:
		if not Rules.integer_in(data.zombies.types[kind].get("threat_cost"), 1, 20):
			errors.append("Zombie threat cost must be a positive whole budget.")
	if not errors.is_empty():
		return
	if int(data.zombies.types.shambler.threat_cost) != 1 or config.first_claim_grace < config.warning_seconds or config.first_seconds < config.warning_seconds or config.maximum_size > config.living_cap:
		errors.append("Pressure preparation, cap or fallback budget is inconsistent.")
	_bands(config, rules, errors)
	_templates(data, rules, errors)
	if not rules.list(config, "routes", false):
		return
	var ids: Array = rules.unique_ids(config.routes)
	if ids != ["east", "west", "north", "south", "north_civic", "south_civic", "north_works", "south_works"]:
		errors.append("Pressure needs the eight authored edge routes.")
	for raw: Variant in config.routes:
		if not raw is Dictionary:
			continue
		var d: Dictionary = raw
		rules.text(d, "name")
		if rules.vec2(d, "entry") and rules.vec2(d, "spread") and rules.vec2(d, "approach"):
			var pos: Vector2 = Routes.point(d.entry)
			var bounds: Vector2 = Routes.point(data.bounds)
			if pos.x < 12 or pos.y < 12 or pos.x > bounds.x - 12 or pos.y > bounds.y - 12 or minf(minf(pos.x, pos.y), minf(bounds.x - pos.x, bounds.y - pos.y)) > 40:
				errors.append("Migration origin must be on a walkable map edge.")
			if Routes.point(d.spread) != (Vector2.DOWN if d.id in ["east", "west"] else Vector2.RIGHT):
				errors.append("Migration spread must follow its map edge.")
	if errors.is_empty():
		_geometry(data, errors)


static func _bands(config: Dictionary, rules: RefCounted, errors: Array[String]) -> void:
	if not rules.list(config, "bands", false):
		return
	if rules.unique_ids(config.bands) != ["hearth", "market", "civic", "works"]:
		errors.append("Pressure needs four ordered campaign bands.")
	for raw: Variant in config.bands:
		if not raw is Dictionary:
			continue
		var before: int = errors.size()
		for key: String in ["budget_min", "budget_max"]:
			if not Rules.integer_in(raw.get(key), 1, int(config.maximum_size)):
				errors.append("Band budget must fit the maximum formation.")
		for key: String in ["interval_min", "interval_max"]:
			rules.number_between(raw, key, float(config.warning_seconds) + 1, 1000)
		if not Rules.integer_in(raw.get("origins"), 1, 2):
			errors.append("A band supports one or two simultaneous origins.")
		if before == errors.size() and (raw.budget_min > raw.budget_max or raw.interval_min > raw.interval_max):
			errors.append("Band budget or interval is reversed.")


static func _templates(data: Dictionary, rules: RefCounted, errors: Array[String]) -> void:
	var config: Dictionary = data.pressure
	if not rules.list(config, "templates", false) or errors.size() > 0:
		return
	rules.unique_ids(config.templates)
	for raw: Variant in config.templates:
		if not raw is Dictionary or not Rules.integer_in(raw.get("band"), 0, 3) or not raw.get("kinds") is Dictionary or raw.kinds.is_empty():
			errors.append("Migration template needs a band and implemented composition.")
			continue
		var cost: int = 0
		var common: int = 0
		for kind: String in raw.kinds:
			if not data.zombies.types.has(kind) or not Rules.integer_in(raw.kinds[kind], 1, int(config.maximum_size)):
				errors.append("Migration template kind/count is invalid.")
				continue
			cost += int(raw.kinds[kind]) * int(data.zombies.types[kind].threat_cost)
			if kind == "shambler":
				common += int(raw.kinds[kind])
		if cost > int(config.bands[int(raw.band)].budget_max) or common * 2 < cost:
			errors.append("Migration template exceeds its band or lacks common pressure.")


static func _geometry(data: Dictionary, errors: Array[String]) -> void:
	var states: Dictionary = {}
	var residents: int = 0
	for p: Dictionary in data.properties:
		states[p.id] = {"open": p.id != "home", "gate_hp": data.balance.gate_health}
		residents += p.zombies.size() + p.reinforcements.size()
	var routes := Routes.new()
	routes.rebuild(data.properties, states, Routes.point(data.bounds))
	if residents > int(data.pressure.living_cap):
		errors.append("Resident population exceeds cap.")
	for p: Dictionary in data.properties:
		for pos: Array in p.zombies + p.reinforcements:
			if not routes.walkable(Routes.point(pos)) or not Routes.rectangle(p.rect).has_point(Routes.point(pos)):
				errors.append("Resident must start in its own walkable yard.")
	for d: Dictionary in data.pressure.routes:
		var start: Vector2 = Routes.point(d.entry)
		var end: Vector2 = Routes.point(d.approach)
		if not routes.walkable(end) or routes.waypoint(start, end).is_equal_approx(start):
			errors.append("Migration entry needs a physical approach to the road.")
		for i: int in range(int(data.pressure.maximum_size)):
			if not routes.walkable(Pressure.entry_position(data, [d.id], int(data.pressure.maximum_size), i)):
				errors.append("Migration formation exceeds the walkable map edge.")
