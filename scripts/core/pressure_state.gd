extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "street.pressure")
	if not rules.object(data, "pressure"):
		return
	var config: Dictionary = data.pressure
	rules.vec2(config, "alley_join")
	for key: String in ["warning_seconds", "interval_seconds", "claim_interval_reduction", "minimum_interval", "spawn_spacing", "join_radius"]:
		rules.number_between(config, key, 1, 1000)
	for key: String in ["base_size", "claim_size", "maximum_size", "living_cap"]:
		if not Rules.integer_in(config.get(key), 1, 100):
			errors.append("Pressure %s must be a positive bounded integer." % key)
	if not errors.is_empty():
		return
	if config.warning_seconds >= config.minimum_interval or config.minimum_interval > config.interval_seconds or config.base_size > config.maximum_size or config.maximum_size > config.living_cap:
		errors.append("Pressure timing or population limits are inconsistent.")
	if not rules.list(config, "routes", false):
		return
	var ids: Array = rules.unique_ids(config.routes)
	if ids != ["east", "west", "north", "south"]:
		errors.append("Pressure needs the four authored edge routes.")
	for raw: Variant in config.routes:
		if not raw is Dictionary:
			errors.append("Raid route must be an object.")
			continue
		var route: Dictionary = raw
		rules.text(route, "name")
		if rules.vec2(route, "entry") and rules.vec2(route, "spread"):
			var pos := Vector2(float(route.entry[0]), float(route.entry[1]))
			var bounds := Vector2(float(data.bounds[0]), float(data.bounds[1]))
			var spread := Vector2(float(route.spread[0]), float(route.spread[1]))
			if pos.x < 12 or pos.y < 12 or pos.x > bounds.x - 12 or pos.y > bounds.y - 12 or minf(minf(pos.x, pos.y), minf(bounds.x - pos.x, bounds.y - pos.y)) > 40:
				errors.append("Raid origin must be on a walkable map edge.")
			if spread != (Vector2.DOWN if route.id in ["east", "west"] else Vector2.RIGHT):
				errors.append("Raid spread must follow its map edge.")
	if rules.list(config, "patterns", false):
		for pattern: Variant in config.patterns:
			if not pattern is Array or pattern.is_empty():
				errors.append("Raid pattern must contain edge routes.")
				continue
			for id: Variant in pattern:
				if not ids.has(id):
					errors.append("Unknown raid route.")
	if errors.is_empty():
		_valid_geometry(data, errors)


static func _valid_geometry(data: Dictionary, errors: Array[String]) -> void:
	var states: Dictionary = {}
	var residents: int = 0
	for p: Dictionary in data.properties:
		states[p.id] = {"open": p.id != "home", "gate_hp": data.balance.gate_health}
		residents += p.zombies.size() + p.reinforcements.size()
	var routes := Routes.new()
	routes.rebuild(data.properties, states, Routes.point(data.bounds))
	if not routes.walkable(Routes.point(data.pressure.alley_join)) or residents > int(data.pressure.living_cap):
		errors.append("Invalid alley junction or resident population exceeds cap.")
	for p: Dictionary in data.properties:
		for pos: Array in p.zombies + p.reinforcements:
			if not routes.walkable(Routes.point(pos)) or not Routes.rectangle(p.rect).has_point(Routes.point(pos)):
				errors.append("Resident must start in its own walkable yard.")
	for entries: Array in data.pressure.patterns:
		for i: int in range(int(data.pressure.maximum_size)):
			if not routes.walkable(Pressure.entry_position(data, entries, int(data.pressure.maximum_size), i)):
				errors.append("Raid formation exceeds the walkable map edge.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("pressure") is Dictionary:
		return false
	var state: Dictionary = data.pressure
	if not Rules.integer_in(state.get("wave"), 0, 1000000000) or not state.get("warned") is bool or not Rules.finite(state.get("next")):
		return false
	if float(state.next) < float(data.elapsed) or float(state.next) - float(data.elapsed) > maxf(float(catalog.pressure.interval_seconds), float(catalog.balance.approach_seconds)) + 0.001 or data.approach != (int(state.wave) > 0):
		return false
	var residents: Dictionary = {}
	var index: int = 0
	for p: Dictionary in catalog.properties:
		for spawn: Array in p.zombies:
			residents["z%d" % index] = p.id
			index += 1
		for i: int in range(p.reinforcements.size()):
			residents["resident_%s_%d" % [p.id, i]] = p.id
	var seen: Dictionary = {}
	var migrants: int = 0
	var living: int = 0
	for z: Dictionary in data.zombies:
		if float(z.hp) > 0:
			living += 1
		if not z.raid:
			if not residents.has(z.id) or z.home != residents[z.id]:
				return false
			seen[z.id] = true
			continue
		migrants += 1
		if z.home != "street" or int(state.wave) == 0:
			return false
		if z.id in ["raid0", "raid1", "raid2"]:
			continue
		var parts: PackedStringArray = z.id.split("_")
		if not z.get("lane_reached") is bool:
			return false
		if parts.size() != 3 or not parts[0].begins_with("wave") or not parts[0].substr(4).is_valid_int() or not parts[2].is_valid_int():
			return false
		var wave: int = int(parts[0].substr(4))
		if wave < 0 or wave >= int(state.wave) or int(parts[2]) < 0 or int(parts[2]) >= int(catalog.pressure.maximum_size):
			return false
		var pattern: Array = catalog.pressure.patterns[wave % catalog.pressure.patterns.size()]
		if parts[1] != pattern[int(parts[2]) % pattern.size()]:
			return false
		var target_found: bool = false
		for p: Dictionary in catalog.properties:
			if z.anchor == p.gate and data.properties[p.id].claimed:
				target_found = true
		if not target_found:
			return false
	return seen.size() == residents.size() and migrants <= int(catalog.pressure.living_cap) and living <= int(catalog.pressure.living_cap)
