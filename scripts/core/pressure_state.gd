extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Content = preload("res://scripts/core/pressure_content.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const Plan = preload("res://scripts/sim/migration_plan.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const LEGACY_PATTERNS: Array = [["east"], ["west"], ["north", "east"], ["south", "west"], ["east", "west", "north", "south"], ["north_civic", "south_civic"], ["north_works", "south_works"]]


static func content(data: Dictionary, errors: Array[String]) -> void:
	Content.content(data, errors)


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("pressure") is Dictionary:
		return false
	var s: Dictionary = data.pressure
	for key: String in ["wave", "origin_repeats"]:
		if not Rules.integer_in(s.get(key), 0, 1000000000):
			return false
	if not Rules.integer_in(s.get("band"), 0, 3) or s.get("phase") not in ["idle", "waiting", "entering"] or not s.get("warned") is bool or not s.get("breached") is bool:
		return false
	for key: String in ["next", "first_claim", "calm_until"]:
		if not Rules.finite(s.get(key)):
			return false
	if float(s.first_claim) < -1 or float(s.first_claim) > float(data.elapsed) or (float(s.first_claim) < 0 and float(s.first_claim) != -1):
		return false
	if float(s.calm_until) < 0 or float(s.calm_until) > float(data.elapsed) + maxf(float(catalog.pressure.calm_seconds), float(catalog.balance.recovery_migration_seconds)) + 0.001:
		return false
	if not s.get("last_origin") is String or (s.last_origin != "" and Plan.route(catalog, s.last_origin).is_empty()) or ((int(s.origin_repeats) == 0) != (s.last_origin == "")):
		return false
	if not s.get("taught") is Array or not s.get("event") is Dictionary or not s.get("last") is Dictionary:
		return false
	var taught: Array[String] = []
	for kind: Variant in s.taught:
		if not kind is String or kind == "shambler" or not catalog.zombies.types.has(kind) or kind in taught:
			return false
		taught.append(kind)
	if data.approach != (int(s.wave) > 0) or int(s.band) < Plan.band(catalog, data.properties):
		return false
	if s.phase == "idle":
		if s.warned or float(s.next) != -1 or float(s.first_claim) != -1 or int(s.wave) != 0 or not s.event.is_empty():
			return false
	else:
		var grace: float = float(catalog.balance.step) + 0.001 if data.defeat_pending else 0.001
		var maximum: float = float(catalog.pressure.first_seconds)
		for b: Dictionary in catalog.pressure.bands:
			maximum = maxf(maximum, float(b.interval_max))
		if float(s.first_claim) < 0 or float(s.next) < float(data.elapsed) - grace or float(s.next) > float(data.elapsed) + maximum + 0.001:
			return false
		if s.event.is_empty():
			if s.phase != "waiting" or s.warned:
				return false
		elif not _event(s, catalog):
			return false
	if not s.last.is_empty() and not _last(s, data, catalog):
		return false
	return _population(data, catalog)


static func _kinds(kinds: Variant, catalog: Dictionary) -> bool:
	if not kinds is Array or kinds.size() > int(catalog.pressure.maximum_size):
		return false
	for kind: Variant in kinds:
		if not kind is String or not catalog.zombies.types.has(kind):
			return false
	return true


static func _entries(entries: Variant, catalog: Dictionary, maximum: int) -> bool:
	if not entries is Array or entries.is_empty() or entries.size() > maximum:
		return false
	var seen: Array[String] = []
	for id: Variant in entries:
		if not id is String or id in seen or Plan.route(catalog, id).is_empty():
			return false
		seen.append(id)
	return true


static func _event(s: Dictionary, catalog: Dictionary) -> bool:
	var e: Dictionary = s.event
	if not e.get("legacy") is bool or not Rules.integer_in(e.get("band"), 0, int(s.band)) or not Rules.integer_in(e.get("budget"), 1, int(catalog.pressure.maximum_size)):
		return false
	if not Rules.integer_in(e.get("wave"), 0, 1000000000) or int(e.wave) != int(s.wave) - (1 if s.phase == "entering" else 0):
		return false
	if not _entries(e.get("entries"), catalog, 4 if e.legacy else int(catalog.pressure.bands[int(e.band)].origins)) or not _kinds(e.get("kinds"), catalog) or e.kinds.is_empty() or not _kinds(e.get("admitted"), catalog):
		return false
	if not Rules.integer_in(e.get("cursor"), 0, e.kinds.size() - 1) or not Rules.integer_in(e.get("skipped"), 0, int(e.cursor)) or e.admitted.size() + int(e.skipped) != int(e.cursor):
		return false
	if s.phase == "waiting" and (int(e.cursor) != 0 or not e.admitted.is_empty()):
		return false
	if Plan.cost(catalog, e.kinds) > int(e.budget) or e.kinds.count("shambler") * 2 < Plan.cost(catalog, e.kinds):
		return false
	if not e.get("template") is String:
		return false
	var known: bool = (e.template == "legacy" and e.legacy) or (e.template == "drift" and not e.legacy)
	for template: Dictionary in catalog.pressure.templates:
		known = known or (template.id == e.template and int(template.band) == int(e.band) and not e.legacy)
	if not e.legacy:
		for kind: String in e.kinds:
			if kind != "shambler" and kind not in s.taught:
				return false
	return known


static func _last(s: Dictionary, data: Dictionary, catalog: Dictionary) -> bool:
	var last: Dictionary = s.last
	if not Rules.integer_in(last.get("wave"), 0, int(s.wave) - 1) or not Rules.integer_in(last.get("band"), 0, int(s.band)) or not last.get("template") is String:
		return false
	if not _entries(last.get("entries"), catalog, 4) or not _kinds(last.get("kinds"), catalog) or not Rules.integer_in(last.get("skipped"), 0, int(catalog.pressure.maximum_size)):
		return false
	if not Rules.finite(last.get("finished")) or float(last.finished) < 0 or float(last.finished) > float(data.elapsed):
		return false
	return last.kinds.size() + int(last.skipped) <= int(catalog.pressure.maximum_size) and Plan.cost(catalog, last.kinds) <= int(catalog.pressure.maximum_size)


static func _population(data: Dictionary, catalog: Dictionary) -> bool:
	var residents: Dictionary = {}
	var index: int = 0
	for p: Dictionary in catalog.properties:
		for spawn: Array in p.zombies:
			residents["z%d" % index] = p.id
			index += 1
		for i: int in range(p.reinforcements.size()):
			residents["resident_%s_%d" % [p.id, i]] = p.id
	for id: String in Boss.resident_ids(catalog):
		residents[id] = Boss.HOME
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
		if z.home != "street" or int(data.pressure.wave) == 0:
			return false
		var identity: Dictionary = _identity(z.id, catalog)
		if identity.is_empty() or int(identity.wave) >= int(data.pressure.wave):
			return false
		if not _migration(z.get("migration"), identity, catalog):
			return false
	return seen.size() == residents.size() and migrants <= int(catalog.pressure.living_cap) and living <= int(catalog.pressure.living_cap)


static func _identity(id: String, catalog: Dictionary) -> Dictionary:
	if id in ["raid0", "raid1", "raid2"]:
		return {"wave": 0, "origin": "east"}
	var parts: PackedStringArray = id.split("_")
	if parts.size() < 3 or not parts[0].begins_with("wave") or not parts[0].substr(4).is_valid_int() or not parts[parts.size() - 1].is_valid_int():
		return {}
	var wave: int = int(parts[0].substr(4))
	var slot: int = int(parts[parts.size() - 1])
	var route_id: String = "_".join(parts.slice(1, parts.size() - 1))
	if wave < 0 or slot < 0 or slot >= int(catalog.pressure.maximum_size) or Plan.route(catalog, route_id).is_empty():
		return {}
	return {"wave": wave, "origin": route_id}


static func _migration(m: Variant, identity: Dictionary, catalog: Dictionary) -> bool:
	if not m is Dictionary or m.get("origin") != identity.origin or not Rules.integer_in(m.get("wave"), int(identity.wave), int(identity.wave)) or m.get("phase") not in ["inward", "seeking", "settled", "exit"]:
		return false
	if not Rules.finite(m.get("blocked")) or float(m.blocked) < 0 or float(m.blocked) > 10 or not m.get("destination") is String:
		return false
	if m.phase == "inward":
		return m.destination == ""
	if m.phase == "exit":
		return not Plan.route(catalog, m.destination).is_empty()
	for p: Dictionary in catalog.properties:
		if p.id == m.destination:
			return p.id != "home"
	return false


static func migrate(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("pressure") is Dictionary or not data.get("zombies") is Array:
		return false
	var old: Dictionary = data.pressure
	if not Rules.integer_in(old.get("wave"), 0, 1000000000) or not Rules.finite(old.get("next")) or not old.get("warned") is bool:
		return false
	var s: Dictionary = Pressure.initial(catalog)
	s.wave = int(old.wave)
	s.band = Plan.band(catalog, data.properties)
	var claims: int = 0
	var discovered: bool = false
	for id: String in data.properties:
		claims += 1 if data.properties[id].claimed else 0
		discovered = discovered or (id != "home" and data.properties[id].looted)
	if data.properties.garage.looted:
		s.taught.append("brute")
	for z: Dictionary in data.zombies:
		if z.raid:
			var identity: Dictionary = _identity(z.id, catalog)
			if identity.is_empty():
				return false
			z.migration = {"origin": identity.origin, "wave": int(identity.wave), "phase": "inward", "destination": "", "blocked": 0.0}
		elif z.get("kind", "shambler") != "shambler" and float(z.hp) <= 0 and z.kind not in s.taught:
			s.taught.append(z.kind)
	if discovered or int(s.wave) > 0 or old.warned:
		s.first_claim = float(data.elapsed)
		s.phase = "waiting"
		s.warned = old.warned
		s.next = maxf(float(old.next), float(data.elapsed) if old.warned else float(data.elapsed) + float(catalog.pressure.warning_seconds))
		var size: int = mini(10, 4 + (maxi(1, claims) - 1) * 2)
		var kinds: Array = ["brute"]
		for i: int in range(size - 1):
			kinds.append("shambler")
		s.event = {"wave": int(s.wave), "band": int(s.band), "template": "legacy", "budget": size + 2, "entries": LEGACY_PATTERNS[int(s.wave) % LEGACY_PATTERNS.size()].duplicate(), "kinds": kinds, "cursor": 0, "admitted": [], "skipped": 0, "legacy": true}
	data.pressure = s
	return true
