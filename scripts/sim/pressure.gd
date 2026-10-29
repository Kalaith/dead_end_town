extends RefCounted
## Finite warned events admit migrants at real edges with no overflow backlog.
const Screecher = preload("res://scripts/sim/screecher.gd")
const Spitter = preload("res://scripts/sim/spitter.gd")
const Runner = preload("res://scripts/sim/runner.gd")
const Plan = preload("res://scripts/sim/migration_plan.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func initial(_data: Dictionary) -> Dictionary:
	return {"wave": 0, "next": -1.0, "warned": false, "phase": "idle", "first_claim": -1.0, "band": 0, "taught": [], "calm_until": 0.0, "breached": false, "last_origin": "", "origin_repeats": 0, "event": {}, "last": {}}


static func add_residents(world: RefCounted) -> void:
	for p: Dictionary in world.catalog.properties:
		for i: int in range(p.reinforcements.size()):
			var kind: String = p.resident_kinds[i] if p.has("resident_kinds") else "shambler"
			var z: Dictionary = world.actor("resident_%s_%d" % [p.id, i], ZombieTypes.type_name(world.catalog, kind), Routes.point(p.reinforcements[i]), ZombieTypes.health(world.catalog, kind))
			z.home = p.id
			z.raid = false
			give_kind(world.catalog, z, kind)
			world.zombies.append(z)


static func give_kind(catalog: Dictionary, z: Dictionary, kind: String) -> void:
	z.kind = kind
	if catalog.zombies.types[kind].has("lunge_range"):
		z.runner = Runner.initial()
	elif kind == "screecher":
		z.screecher = Screecher.initial()
	elif kind == "spitter":
		z.spitter = Spitter.initial()


static func claimed(world: RefCounted, id: String) -> void:
	Plan.observe(world)
	if id == "home" or float(world.pressure.first_claim) >= 0:
		return
	world.pressure.first_claim = world.elapsed
	Plan.schedule(world, maxf(float(world.catalog.pressure.first_seconds), world.elapsed + float(world.catalog.pressure.first_claim_grace)))


static func postpone(world: RefCounted, until: float) -> void:
	world.pressure.calm_until = maxf(float(world.pressure.calm_until), until)
	if world.pressure.phase != "idle" and float(world.pressure.next) < until:
		world.pressure.next = until
		world.pressure.warned = false


static func _breached(world: RefCounted) -> bool:
	for p: Dictionary in world.catalog.properties:
		if world.properties[p.id].claimed and world.remaining(p.id) > 0:
			return true
	return false


static func step(world: RefCounted) -> void:
	Plan.observe(world)
	var state: Dictionary = world.pressure
	var breached: bool = _breached(world)
	if int(state.wave) > 0 and state.phase != "entering" and (breached or state.breached):
		postpone(world, world.elapsed + float(world.catalog.pressure.calm_seconds))
	state.breached = breached
	if state.phase == "idle":
		return
	if state.event.is_empty():
		if world.elapsed >= float(state.next):
			Plan.schedule(world, world.elapsed + float(world.catalog.pressure.warning_seconds))
		return
	if not state.warned and world.elapsed >= float(state.next) - float(world.catalog.pressure.warning_seconds):
		state.warned = true
		world.note("RADIO / About %d approaching from %s in %ds." % [state.event.kinds.size() - int(state.event.cursor), route_names(world), maxi(0, ceili(float(state.next) - world.elapsed))])
	if world.elapsed + 0.000001 < float(state.next):
		return
	if state.phase == "waiting":
		_start(world)
	_admit(world)


static func _start(world: RefCounted) -> void:
	var state: Dictionary = world.pressure
	var retained: Array[Dictionary] = []
	for z: Dictionary in world.zombies:
		if not z.raid or float(z.hp) > 0:
			retained.append(z)
		else:
			world.memories.erase(z.id)
	world.zombies = retained
	state.phase = "entering"
	state.wave = int(state.wave) + 1
	world.approach = true
	world.note("RADIO / Movement entering from %s." % route_names(world))


static func _counts(world: RefCounted) -> Dictionary:
	var counts: Dictionary = {"living": 0}
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0:
			var kind: String = str(z.get("kind", "shambler"))
			counts.living = int(counts.living) + 1
			counts[kind] = int(counts.get(kind, 0)) + 1
	return counts


static func _admit(world: RefCounted) -> void:
	var state: Dictionary = world.pressure
	var event: Dictionary = state.event
	var counts: Dictionary = _counts(world)
	if int(counts.living) >= int(world.catalog.pressure.living_cap):
		event.skipped = int(event.skipped) + event.kinds.size() - int(event.cursor)
		event.cursor = event.kinds.size()
		_finish(world)
		return
	var index: int = int(event.cursor)
	var kind: String = event.kinds[index]
	if world.catalog.pressure.special_caps.has(kind) and int(counts.get(kind, 0)) >= int(world.catalog.pressure.special_caps[kind]):
		# Replace the special's complete threat budget, without an invisible retry.
		event.kinds.remove_at(index)
		for i: int in range(int(world.catalog.zombies.types[kind].threat_cost)):
			event.kinds.insert(index, "shambler")
		kind = "shambler"
	var id: String = event.entries[index % event.entries.size()]
	var pos: Vector2 = entry_position(world.catalog, event.entries, event.kinds.size(), index)
	var occupied: bool = not world.routes.walkable(pos)
	for z: Dictionary in world.zombies:
		occupied = occupied or (float(z.hp) > 0 and z.pos.distance_to(pos) < 22)
	if occupied:
		event.skipped = int(event.skipped) + 1
	else:
		var z: Dictionary = world.actor("wave%d_%s_%d" % [int(event.wave), id, index], ZombieTypes.type_name(world.catalog, kind), pos, ZombieTypes.health(world.catalog, kind))
		give_kind(world.catalog, z, kind)
		z.home = "street"
		z.raid = true
		z.migration = {"origin": id, "wave": int(event.wave), "phase": "inward", "destination": "", "blocked": 0.0}
		world.zombies.append(z)
		event.admitted.append(kind)
	event.cursor = index + 1
	if int(event.cursor) >= event.kinds.size():
		_finish(world)
	else:
		state.next = world.elapsed + float(world.catalog.pressure.entry_seconds)


static func _finish(world: RefCounted) -> void:
	var state: Dictionary = world.pressure
	var event: Dictionary = state.event
	state.last = {"wave": int(event.wave), "band": int(event.band), "template": event.template, "entries": event.entries.duplicate(), "kinds": event.admitted.duplicate(), "skipped": int(event.skipped), "finished": world.elapsed}
	if event.entries.size() == 1:
		var id: String = event.entries[0]
		state.origin_repeats = int(state.origin_repeats) + 1 if state.last_origin == id else 1
		state.last_origin = id
	else:
		state.last_origin = ""
		state.origin_repeats = 0
	Plan.schedule(world, world.elapsed + Plan.interval(world))


static func route_definition(data: Dictionary, id: String) -> Dictionary:
	return Plan.route(data, id)


static func entry_position(data: Dictionary, entries: Array, size: int, index: int) -> Vector2:
	var d: Dictionary = Plan.route(data, entries[index % entries.size()])
	var rank: int = index / entries.size()
	var route_count: int = (size - 1 - index % entries.size()) / entries.size() + 1
	var offset: float = (float(rank) - float(route_count - 1) * 0.5) * float(data.pressure.spawn_spacing)
	return Routes.point(d.entry) + Routes.point(d.spread) * offset


static func route_names(world: RefCounted) -> String:
	var names: PackedStringArray = []
	for id: String in world.pressure.event.entries:
		names.append(Plan.route(world.catalog, id).name)
	return " / ".join(names)
