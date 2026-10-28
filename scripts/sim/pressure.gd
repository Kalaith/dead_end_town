extends RefCounted
const Runner = preload("res://scripts/sim/runner.gd")
## Bounded, deterministic map-edge migrations. Cleared residents never respawn.
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func initial(data: Dictionary) -> Dictionary:
	return {"wave": 0, "next": float(data.balance.approach_seconds), "warned": false}


static func add_residents(world: RefCounted) -> void:
	for p: Dictionary in world.catalog.properties:
		for i: int in range(p.reinforcements.size()):
			var z: Dictionary = world.actor("resident_%s_%d" % [p.id, i], "Shambler", Routes.point(p.reinforcements[i]), ZombieTypes.health(world.catalog))
			z.home = p.id
			z.raid = false
			if p.has("resident_kinds"):
				z.kind = p.resident_kinds[i]
				z.name = ZombieTypes.type_name(world.catalog, z.kind)
				z.hp = ZombieTypes.health(world.catalog, z.kind)
				if z.kind == "runner":
					z.runner = Runner.initial()
			world.zombies.append(z)


static func origins(world: RefCounted) -> Array:
	var patterns: Array = world.catalog.pressure.patterns
	return patterns[int(world.pressure.wave) % patterns.size()]


static func step(world: RefCounted) -> void:
	var config: Dictionary = world.catalog.pressure
	if not world.pressure.warned and world.elapsed >= float(world.pressure.next) - float(config.warning_seconds):
		world.pressure.warned = true
		world.note("RADIO / Incoming from %s. Take defensive positions." % route_names(world))
	if world.elapsed < float(world.pressure.next):
		return
	# Remove defeated migrants only; resident corpses record permanent clearances.
	var retained: Array[Dictionary] = []
	var living: int = 0
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0:
			living += 1
		if not z.raid or float(z.hp) > 0:
			retained.append(z)
	world.zombies = retained
	var claims: int = 0
	for p: Dictionary in world.properties.values():
		if p.claimed:
			claims += 1
	var size: int = mini(int(config.maximum_size), int(config.base_size) + (maxi(1, claims) - 1) * int(config.claim_size))
	size = mini(size, maxi(0, int(config.living_cap) - living))
	var entries: Array = origins(world)
	for i: int in range(size):
		var route_id: String = entries[i % entries.size()]
		var pos: Vector2 = entry_position(world.catalog, entries, size, i)
		var kind: String = special_kind(config, int(world.pressure.wave), i)
		var z: Dictionary = world.actor("wave%d_%s_%d" % [int(world.pressure.wave), route_id, i], ZombieTypes.type_name(world.catalog, kind), pos, ZombieTypes.health(world.catalog, kind))
		if kind != "":
			z.kind = kind
			if kind == "runner":
				z.runner = Runner.initial()
		z.home = "street"
		z.raid = true
		# Spawn at a real edge; the same random wandering applies to every zombie.
		world.zombies.append(z)
	if size > 0:
		world.note("RADIO / Shamblers entering from %s." % route_names(world))
	world.approach = true
	world.pressure.wave = int(world.pressure.wave) + 1
	world.pressure.next = world.elapsed + maxf(float(config.minimum_interval), float(config.interval_seconds) - (maxi(1, claims) - 1) * float(config.claim_interval_reduction))
	world.pressure.warned = false


## Special kinds take the first spawn slots of a wave, in the order authored.
static func special_kind(config: Dictionary, wave: int, index: int) -> String:
	var slot: int = 0
	for entry: Dictionary in config.specials:
		if wave < int(entry.from_wave):
			continue
		slot += int(entry.count)
		if index < slot:
			return entry.kind
	return ""


static func route_definition(data: Dictionary, id: String) -> Dictionary:
	for route: Dictionary in data.pressure.routes:
		if route.id == id:
			return route
	return {}


static func entry_position(data: Dictionary, entries: Array, size: int, index: int) -> Vector2:
	var route: Dictionary = route_definition(data, entries[index % entries.size()])
	var rank: int = index / entries.size()
	var route_count: int = (size - 1 - index % entries.size()) / entries.size() + 1
	var offset: float = (float(rank) - float(route_count - 1) * 0.5) * float(data.pressure.spawn_spacing)
	return Routes.point(route.entry) + Routes.point(route.spread) * offset


static func route_names(world: RefCounted) -> String:
	var names: PackedStringArray = []
	for id: String in origins(world):
		names.append(route_definition(world.catalog, id).name)
	return " / ".join(names)
