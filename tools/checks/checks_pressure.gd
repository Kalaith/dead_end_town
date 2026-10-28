extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const SaveState = preload("res://scripts/core/save_state.gd")


func check_resident_population_and_occupied_claims() -> String:
	var w := World.new(Catalog.read())
	for entry: Array in [["garden", 7], ["library", 7], ["garage", 10]]:
		if w.remaining(entry[0]) != entry[1] or w.claim(entry[0]):
			return "Property population or occupied claim refusal is wrong."
	for z: Dictionary in w.zombies:
		if not w.routes.walkable(z.pos):
			return "Resident spawned in a fence or building: " + z.id
	return ""


func check_raids_warn_recur_and_use_every_edge_without_teleporting() -> String:
	var w := World.new(Catalog.read())
	var origins: Dictionary = {}
	for wave: int in range(w.catalog.pressure.patterns.size()):
		w.elapsed = float(w.pressure.next) - float(w.catalog.pressure.warning_seconds)
		Pressure.step(w)
		if not w.pressure.warned or not w.messages.back().contains("Incoming"):
			return "Missing pre-arrival warning."
		var before: int = w.zombies.size()
		Pressure.step(w)
		if w.zombies.size() != before:
			return "Raid spawned before its arrival."
		w.elapsed = float(w.pressure.next)
		Pressure.step(w)
		var count: int = 0
		for z: Dictionary in w.zombies:
			if not z.raid:
				continue
			count += 1
			origins[z.id.get_slice("_", 1) + ("_" + z.id.get_slice("_", 2) if z.id.get_slice("_", 2) in ["civic", "works"] else "")] = true
			if not w.routes.walkable(z.pos) or minf(minf(z.pos.x, z.pos.y), minf(float(w.catalog.bounds[0]) - z.pos.x, float(w.catalog.bounds[1]) - z.pos.y)) > 40:
				return "Raid did not enter through a walkable map edge."
			z.hp = 0.0
		if count != 4 or int(w.pressure.wave) != wave + 1:
			return "Repeated home-only raid has incorrect size or sequence."
	return "Not all authored origins used" if origins.size() != w.catalog.pressure.routes.size() else ""


func check_expansion_increases_size_frequency_and_spreads_edge_arrivals() -> String:
	var w: RefCounted = _expanded()
	w.pressure.wave = 4
	w.approach = true
	w.elapsed = float(w.pressure.next)
	Pressure.step(w)
	var targets: Dictionary = {}
	var count: int = 0
	for z: Dictionary in w.zombies:
		if z.raid:
			count += 1
			targets[z.anchor] = true
	if count != 10 or targets.size() < 3 or not is_equal_approx(float(w.pressure.next) - w.elapsed, 41):
		return "Expansion failed to grow, accelerate or spread attacks."
	return ""


func check_raid_population_and_corpse_storage_stay_bounded() -> String:
	var w := World.new(Catalog.read())
	var resident_count: int = w.zombies.size()
	var save := SaveState.new(w.catalog)
	for i: int in range(80):
		w.elapsed = float(w.pressure.next)
		Pressure.step(w)
		var living: int = 0
		for z: Dictionary in w.zombies:
			if float(z.hp) > 0:
				living += 1
		if living > int(w.catalog.pressure.living_cap) or w.zombies.size() > resident_count + int(w.catalog.pressure.living_cap) or not save.valid(save.snapshot(w)):
			return "Raid cap or bounded save validation failed."
		if i % 7 == 0:
			for z: Dictionary in w.zombies:
				if z.raid:
					z.hp = 0.0
	return ""


func check_warned_raid_reload_is_deterministic_and_rejects_bad_state() -> String:
	var w: RefCounted = _expanded()
	w.elapsed = float(w.pressure.next) - 10
	Pressure.step(w)
	var save := SaveState.new(w.catalog)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(save.snapshot(w)))
	var loaded: RefCounted = save.restore(raw)
	if loaded == null:
		return "Warning snapshot rejected."
	for i: int in range(500):
		w.step(0.05)
		loaded.step(0.05)
	if save.snapshot(w) != save.snapshot(loaded):
		return "Reload duplicated or changed an incoming wave."
	for broken: Variant in [-1, "bad", 1.5]:
		raw = save.snapshot(w)
		raw.pressure.wave = broken
		if save.valid(raw):
			return "Malformed raid counter accepted."
	raw = save.snapshot(w)
	raw.pressure.next = w.elapsed - 1
	if save.valid(raw):
		return "Past raid clock accepted."
	raw = save.snapshot(w)
	for z: Dictionary in raw.zombies:
		if z.raid:
			z.roam_angle = "bad"
			if save.valid(raw):
				return "Invalid migrant wandering state accepted."
			break
	return ""


func check_real_schema_four_migration_preserves_cleared_territory_and_legacy_raid() -> String:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		if z.home == "garden":
			z.hp = 0.0
	w.claim("garden")
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 4
	old.erase("pressure")
	old.approach = true
	old.elapsed = 400.0
	var legacy: Array = []
	for z: Dictionary in old.zombies:
		if not z.id.begins_with("resident_"):
			legacy.append(z)
	for i: int in range(3):
		var z: Dictionary = w.actor("raid%d" % i, "Shambler", Vector2(1300 + i * 28, 580), 60)
		z.raid = true
		z.home = "street"
		legacy.append(save._encode_actor(z))
	old.zombies = legacy
	var loaded: RefCounted = save.restore(old)
	if loaded == null or loaded.remaining("garden") != 0 or loaded.remaining("garage") != 10 or loaded.materials != w.materials:
		return "Legacy save lost progress or repopulated a cleared yard."
	if int(loaded.pressure.wave) != 1 or not is_equal_approx(float(loaded.pressure.next), 465):
		return "Legacy save did not preserve first-raid history and preparation time."
	return ""


func check_alley_migrants_wander_without_a_fixed_road_destination() -> String:
	var w: RefCounted = _expanded()
	w.pressure.wave = 4
	w.approach = true
	w.elapsed = float(w.pressure.next)
	Pressure.step(w)
	var starts: Dictionary = {}
	for z: Dictionary in w.zombies:
		if z.raid and (z.id.contains("_north_") or z.id.contains("_south_")):
			starts[z.id] = z.pos
	for i: int in range(100):
		w.step(0.05)
	for z: Dictionary in w.zombies:
		if starts.has(z.id) and z.pos.distance_to(starts[z.id]) < 5:
			return "Alley migrant did not wander away from its spawn."
	return ""


func check_pressure_catalog_rejects_missing_invalid_and_unknown_content() -> String:
	var data: Dictionary = Catalog.read()
	data.pressure.erase("living_cap")
	if Catalog.problems(data).is_empty():
		return "Missing population cap accepted."
	data = Catalog.read()
	data.pressure.patterns[0] = ["teleport"]
	if Catalog.problems(data).is_empty():
		return "Unknown approach accepted."
	data = Catalog.read()
	data.pressure.routes[0].entry = [720, 580]
	return "Interior spawn accepted" if Catalog.problems(data).is_empty() else ""


func _expanded() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		w.claim(id)
	return w
