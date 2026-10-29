extends RefCounted
## Spitter: aims at a committed point, then lobs a slow glob that leaves a short-lived pool.
## Globs and pools are transient hazards; they are not saved, only the spitter's own intent is.
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")


static func initial() -> Dictionary:
	return {"phase": "idle", "left": 0.0, "retry": 0.0, "tx": 0.0, "ty": 0.0}


static func is_spitter(z: Dictionary) -> bool:
	return z.get("kind") == "spitter"


static func interrupt(world: RefCounted, z: Dictionary) -> void:
	if not is_spitter(z) or z.spitter.phase != "aim":
		return
	z.spitter.phase = "idle"
	z.spitter.left = 0.0
	z.spitter.retry = float(ZombieTypes.kind(world.catalog, z).spit_retry)


## A spitter in range with a clear shot stands still and waits out its cooldown.
static func holds(world: RefCounted, z: Dictionary, target: Dictionary) -> bool:
	if not is_spitter(z) or target.is_empty():
		return false
	var config: Dictionary = ZombieTypes.kind(world.catalog, z)
	var distance: float = z.pos.distance_to(target.pos)
	return distance >= float(config.spit_min) and distance <= float(config.spit_range) and world.routes.line_clear(z.pos, target.pos, true)


static func step(world: RefCounted, z: Dictionary, target: Dictionary, dt: float) -> bool:
	if not is_spitter(z):
		return false
	var config: Dictionary = ZombieTypes.kind(world.catalog, z)
	var state: Dictionary = z.spitter
	state.retry = maxf(0.0, float(state.retry) - dt)
	if state.phase == "aim":
		state.left = maxf(0.0, float(state.left) - dt)
		var point := Vector2(float(state.tx), float(state.ty))
		z.facing = z.pos.direction_to(point)
		if float(state.left) <= 0:
			state.phase = "idle"
			state.retry = float(config.spit_cooldown)
			world.spits.append({"t": "glob", "x": z.pos.x, "y": z.pos.y, "tx": point.x, "ty": point.y})
		return true
	if holds(world, z, target) and float(state.retry) <= 0 and float(z.cooldown) <= 0:
		state.phase = "aim"
		state.left = float(config.spit_tell)
		state.tx = target.pos.x
		state.ty = target.pos.y
		z.facing = z.pos.direction_to(target.pos)
		return true
	return false


## Where hazards are or are about to be: pools, globs in flight and the points spitters are aiming at.
static func threats(world: RefCounted) -> Array[Vector2]:
	var found: Array[Vector2] = []
	for s: Dictionary in world.spits:
		found.append(Vector2(float(s.tx), float(s.ty)) if s.t == "glob" else Vector2(float(s.x), float(s.y)))
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and is_spitter(z) and z.spitter.phase == "aim":
			found.append(Vector2(float(z.spitter.tx), float(z.spitter.ty)))
	return found


## A nearby clear point for someone standing inside a hazard, or Vector2.INF when they are safe.
static func escape(world: RefCounted, from: Vector2) -> Vector2:
	var found: Array[Vector2] = threats(world)
	if found.is_empty():
		return Vector2.INF
	var config: Dictionary = world.catalog.zombies.types.spitter
	var radius: float = float(config.pool_radius) + 14.0
	var nearest: Vector2 = Vector2.INF
	for centre: Vector2 in found:
		if from.distance_to(centre) < radius and (not nearest.is_finite() or from.distance_to(centre) < from.distance_to(nearest)):
			nearest = centre
	if not nearest.is_finite():
		return Vector2.INF
	var away: Vector2 = nearest.direction_to(from)
	if away.is_zero_approx():
		away = Vector2.RIGHT
	# Try straight out first, then fan round until a walkable, hazard-free point is found.
	for turn: float in [0.0, 0.6, -0.6, 1.2, -1.2, 1.9, -1.9, PI]:
		var point: Vector2 = nearest + away.rotated(turn) * (radius + 10.0)
		if world.routes.walkable(point) and world.routes.travel_clear(from, point) and found.all(func(centre: Vector2) -> bool: return centre.distance_to(point) >= radius):
			return point
	return Vector2.INF


## Moves every glob and ages every pool for one fixed step.
static func advance(world: RefCounted, dt: float) -> void:
	if world.spits.is_empty():
		return
	var config: Dictionary = world.catalog.zombies.types.spitter
	var kept: Array[Dictionary] = []
	for s: Dictionary in world.spits:
		if s.t == "glob":
			if not _fly(world, s, config, dt):
				kept.append(s)
		else:
			s.age = float(s.age) + dt
			while float(s.age) >= float(s.tick) and float(s.tick) <= float(config.pool_seconds):
				_pool_tick(world, s, config)
				s.tick = float(s.tick) + 1.0
			if float(s.age) < float(config.pool_seconds):
				kept.append(s)
	world.spits = kept


## True once the glob has landed (on a person, a solid obstacle or its committed point).
static func _fly(world: RefCounted, s: Dictionary, config: Dictionary, dt: float) -> bool:
	var pos := Vector2(float(s.x), float(s.y))
	var goal := Vector2(float(s.tx), float(s.ty))
	var travel: float = float(config.spit_speed) * dt
	while travel > 0.0001:
		var stride: float = minf(4.0, minf(travel, pos.distance_to(goal)))
		var next: Vector2 = pos.move_toward(goal, stride)
		# Walls and closed gates stop it; low road barriers do not.
		if not world.routes.line_clear(pos, next, true):
			_splash(world, pos, config, null)
			return true
		if Vehicle.driving(world) and next.distance_to(Vehicle.pos(world)) < 30:
			Vehicle.hit(world, float(config.spit_damage))
			_splash(world, next, config, null)
			return true
		for person: Dictionary in [world.player] + world.survivors:
			if float(person.hp) > 0 and next.distance_to(person.pos) < 18:
				_splash(world, next, config, person)
				return true
		pos = next
		travel -= maxf(stride, 0.0001)
		if pos.distance_to(goal) < 0.5:
			_splash(world, pos, config, null)
			return true
	s.x = pos.x
	s.y = pos.y
	return false


static func _splash(world: RefCounted, at: Vector2, config: Dictionary, victim: Variant) -> void:
	if victim != null:
		var damage: float = float(config.spit_damage)
		if Equipment.protected(world, victim):
			damage *= float(world.balance.armour_damage_multiplier)
		if Equipment.shielded(world, victim) and victim.facing.dot(victim.pos.direction_to(at)) > 0.2:
			damage *= float(world.balance.shield_damage_multiplier)
		victim.hp = maxf(0.0, float(victim.hp) - damage)
		victim.flash = 0.18
	world.spits.append({"t": "pool", "x": at.x, "y": at.y, "age": 0.0, "tick": 1.0})


## Overlapping pools share a one-second per-person cooldown, so they never stack.
static func _pool_tick(world: RefCounted, s: Dictionary, config: Dictionary) -> void:
	var centre := Vector2(float(s.x), float(s.y))
	for person: Dictionary in [world.player] + world.survivors:
		if float(person.hp) <= 0 or Vehicle.occupant(world, person) or person.pos.distance_to(centre) > float(config.pool_radius):
			continue
		if world.elapsed - float(world.spit_hits.get(person.id, -10.0)) < 0.99:
			continue
		world.spit_hits[person.id] = world.elapsed
		var damage: float = float(config.pool_damage)
		if Equipment.protected(world, person):
			damage *= float(world.balance.armour_damage_multiplier)
		person.hp = maxf(0.0, float(person.hp) - damage)
		person.flash = 0.18
