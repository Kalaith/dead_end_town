extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const TownState = preload("res://scripts/core/town_state.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Exploration = preload("res://scripts/sim/exploration.gd")


static func quiet() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	return w


func check_full_town_has_24_sites_34_links_and_24_independent_barriers() -> String:
	var c: Dictionary = Catalog.read()
	if c.properties.size() != 24 or c.passages.size() != 22 or c.crossings.size() != 12 or c.barricades.size() != 24 or c.town.core.size() != 18:
		return "Full authored town topology is incomplete."
	var w: RefCounted = quiet()
	var stock: int = w.materials
	if w.claim("greenhouse") or w.properties.greenhouse.looted or w.materials != stock:
		return "Unimplemented shell granted a reward."
	w.player.pos = Vector2(3960, 350)
	return "Development shell has a misleading live approval" if w.context() != "Unfinished" else ""


func check_all_sites_have_physical_routes_and_the_far_relay_is_reachable_on_foot() -> String:
	var w: RefCounted = quiet()
	w.properties.home.open = true
	w.rebuild_routes()
	var start := Vector2(50, 580)
	for p: Dictionary in w.catalog.properties:
		var destination: Vector2 = Routes.point(p.site)
		var path: PackedVector2Array = w.routes.grid.get_point_path(Vector2i(start / 20.0), Vector2i(destination / 20.0))
		if path.is_empty():
			return "Unreachable property work point: " + str(p.id)
	w.player.pos = start
	w.pressure.next = 10000.0
	for i: int in range(1100):
		w.move_input = Vector2.RIGHT if w.player.pos.x < 8275 else Vector2.UP
		w.step(0.05)
		if w.player.pos.distance_to(Vector2(8280, 350)) < 14:
			return ""
	return "Physical movement failed to cross the town without teleporting."


func check_core_only_protected_route_does_not_require_optional_properties() -> String:
	var w: RefCounted = quiet()
	for p: Dictionary in w.catalog.properties:
		w.properties[p.id].claimed = p.core
		w.properties[p.id].looted = p.core
		w.properties[p.id].open = true
	for d: Dictionary in w.catalog.passages:
		if d.requires[0] in w.catalog.town.core and d.requires[1] in w.catalog.town.core:
			w.passages[d.id] = {"started": true, "done": true, "progress": float(w.balance.passage_seconds), "hp": float(w.balance.gate_health), "open": true, "repair_reserved": false}
	for d: Dictionary in w.catalog.barricades:
		if d.requires[0] in w.catalog.town.core and d.requires[1] in w.catalog.town.core:
			w.roadworks[d.id] = {"phase": "ready", "hp": float(w.balance.barricade_health), "progress": 0.0, "repair_reserved": false}
	w.rebuild_routes()
	for id: String in w.catalog.town.core:
		if not w.safe_connected(id):
			return "Core route secretly needs an optional property: " + id
	var west: Dictionary = w.catalog.crossings[0]
	var east: Dictionary = w.catalog.crossings[1]
	w.roadworks.home_east = {"phase": "empty", "hp": 0.0, "progress": 0.0, "repair_reserved": false}
	w.rebuild_routes()
	if Neighbourhood.link_reason(w, west).is_empty() or not Neighbourhood.link_reason(w, east).is_empty() or not w.routes.walkable(Vector2(720, 580)):
		return "Neighbouring crossings share a barrier or hide the exposed alley."
	return ""


func check_schema_nineteen_six_site_save_expands_without_rewriting_old_progress() -> String:
	var w: RefCounted = quiet()
	w.claim("garden")
	w.player.pos = Vector2(1080, 350)
	w.interact()
	w.slice_state.phase = "complete"
	w.slice_state.held = 60.0
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 19
	old.erase("seen")
	for id: String in old.properties.keys():
		if id not in TownState.LEGACY:
			old.properties.erase(id)
	for id: String in old.roadworks.keys():
		if id not in TownState.OLD_ROADS:
			old.roadworks.erase(id)
	for id: String in old.passages.keys():
		if id not in TownState.OLD_PASSAGES:
			old.passages.erase(id)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.properties.size() != 24 or loaded.materials != w.materials or loaded.food != w.food or loaded.roam_rng.state != w.roam_rng.state or loaded.zombies.size() != w.zombies.size():
		return "Original street migration lost supplies, actors or deterministic state."
	for id: String in TownState.LEGACY:
		if loaded.properties[id] != w.properties[id]:
			return "Original property changed on expansion: " + id
	return "Expansion erased earned watch or paid work" if loaded.slice_state.phase != "complete" or loaded.orders != w.orders else ""


func check_exploration_persists_without_revealing_distant_properties() -> String:
	var w: RefCounted = quiet()
	if w.seen.has("relay") or w.seen.has("clinic"):
		return "New game reveals distant sites."
	w.player.pos = Vector2(8280, 580)
	Exploration.update(w)
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or not loaded.seen.has("relay") or loaded.seen.has("clinic"):
		return "Scouting did not persist locally."
	return ""


func check_rasterised_route_grid_matches_collision_and_clears_removed_barriers() -> String:
	var w: RefCounted = quiet()
	for d: Dictionary in w.catalog.barricades:
		w.roadworks[d.id] = {"phase": "ready", "hp": float(w.balance.barricade_health), "progress": 0.0, "repair_reserved": false}
	w.rebuild_routes()
	for x: int in range(w.routes.grid.region.size.x):
		for y: int in range(w.routes.grid.region.size.y):
			var cell := Vector2i(x, y)
			var point: Vector2 = Vector2(cell) * 20.0 + Vector2(10, 10)
			if w.routes.grid.is_point_solid(cell) == w.routes.walkable(point):
				return "Route raster differs from collision at " + str(point)
	w.roadworks.home_east = {"phase": "empty", "hp": 0.0, "progress": 0.0, "repair_reserved": false}
	w.rebuild_routes()
	return "Removed defence left stale route cells" if w.routes.grid.is_point_solid(Vector2i(31, 29)) else ""
