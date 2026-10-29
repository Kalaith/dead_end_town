extends RefCounted
## Scheduling changes composition, routes and intervals, never enemy statistics.
const Routes = preload("res://scripts/sim/routes.gd")
const Facility = preload("res://scripts/sim/facility.gd")


static func connected(catalog: Dictionary, properties: Dictionary) -> Array[String]:
	var held: Array[String] = []
	if not properties.home.claimed:
		return held
	held.append("home")
	var cursor: int = 0
	while cursor < held.size():
		for p: Dictionary in catalog.properties:
			if p.id == held[cursor]:
				for id: String in p.neighbors:
					if properties[id].claimed and id not in held:
						held.append(id)
		cursor += 1
	return held


static func band(catalog: Dictionary, properties: Dictionary) -> int:
	var held: Array[String] = connected(catalog, properties)
	var result: int = 0
	for id: String in held:
		if id in catalog.town.core:
			result = maxi(result, int(catalog.town.bands[id]))
	return result


static func observe(world: RefCounted) -> void:
	world.pressure.band = maxi(int(world.pressure.band), band(world.catalog, world.properties))
	if Facility.state(world, "garage").looted and "brute" not in world.pressure.taught:
		world.pressure.taught.append("brute")
	for z: Dictionary in world.zombies:
		var kind: String = str(z.get("kind", "shambler"))
		if z.raid or kind == "shambler" or kind in world.pressure.taught:
			continue
		if float(z.hp) <= 0 or z.pos.distance_to(world.player.pos) <= float(world.balance.zombie_notice_range):
			world.pressure.taught.append(kind)


static func route(catalog: Dictionary, id: String) -> Dictionary:
	for entry: Dictionary in catalog.pressure.routes:
		if entry.id == id:
			return entry
	return {}


static func cost(catalog: Dictionary, kinds: Array) -> int:
	var result: int = 0
	for kind: String in kinds:
		result += int(catalog.zombies.types[kind].threat_cost)
	return result


static func composition(world: RefCounted, budget: int) -> Dictionary:
	var eligible: Array[Dictionary] = []
	for template: Dictionary in world.catalog.pressure.templates:
		if int(template.band) != int(world.pressure.band):
			continue
		var kinds: Array = []
		var known: bool = true
		var ids: Array = template.kinds.keys()
		ids.sort()
		for kind: String in ids:
			known = known and (kind == "shambler" or kind in world.pressure.taught)
			for i: int in range(int(template.kinds[kind])):
				kinds.append(kind)
		if known and cost(world.catalog, kinds) <= budget:
			eligible.append({"template": template.id, "kinds": kinds})
	if not eligible.is_empty():
		return eligible[world.roam_rng.randi_range(0, eligible.size() - 1)]
	var kinds: Array = []
	kinds.resize(budget)
	kinds.fill("shambler")
	return {"template": "drift", "kinds": kinds}


static func origins(world: RefCounted, maximum: int) -> Array:
	var valid: Array = []
	for d: Dictionary in world.catalog.pressure.routes:
		var start: Vector2 = Routes.point(d.entry)
		var end: Vector2 = Routes.point(d.approach)
		if world.routes.walkable(start) and world.routes.walkable(end) and (world.routes.travel_clear(start, end) or not world.routes.waypoint(start, end).is_equal_approx(start)):
			valid.append(d.id)
	if valid.size() > 1 and int(world.pressure.origin_repeats) >= 2:
		valid.erase(world.pressure.last_origin)
	var selected: Array = []
	var count: int = world.roam_rng.randi_range(1, mini(maximum, valid.size())) if not valid.is_empty() else 0
	for i: int in range(count):
		var index: int = world.roam_rng.randi_range(0, valid.size() - 1)
		selected.append(valid[index])
		valid.remove_at(index)
	return selected


static func schedule(world: RefCounted, when: float) -> bool:
	var config: Dictionary = world.catalog.pressure.bands[int(world.pressure.band)]
	var entries: Array = origins(world, int(config.origins))
	if entries.is_empty():
		world.pressure.next = world.elapsed + float(world.catalog.pressure.route_retry_seconds)
		world.pressure.event = {}
		world.pressure.phase = "waiting"
		return false
	var budget: int = world.roam_rng.randi_range(int(config.budget_min), int(config.budget_max))
	var chosen: Dictionary = composition(world, budget)
	world.pressure.event = {"wave": int(world.pressure.wave), "band": int(world.pressure.band), "template": chosen.template, "budget": budget, "entries": entries, "kinds": chosen.kinds, "cursor": 0, "admitted": [], "skipped": 0, "legacy": false}
	world.pressure.next = maxf(when, float(world.pressure.calm_until))
	world.pressure.phase = "waiting"
	world.pressure.warned = false
	return true


static func interval(world: RefCounted) -> float:
	var config: Dictionary = world.catalog.pressure.bands[int(world.pressure.band)]
	return world.roam_rng.randf_range(float(config.interval_min), float(config.interval_max))
