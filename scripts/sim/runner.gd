extends RefCounted
## A committed, collision-stopped lunge. Numeric intent is directly JSON safe.
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")


static func initial() -> Dictionary:
	return {"phase": "idle", "left": 0.0, "distance": 0.0, "dx": 0.0, "dy": 1.0, "retry": 0.0}


static func interrupt(world: RefCounted, z: Dictionary) -> void:
	if ZombieTypes.charges(world.catalog, z) and z.runner.phase in ["tell", "dash"] and not bool(ZombieTypes.kind(world.catalog, z).get("uninterruptible", false)):
		_recover(world, z)


static func _recover(world: RefCounted, z: Dictionary) -> void:
	var config: Dictionary = ZombieTypes.kind(world.catalog, z)
	z.runner.phase = "recover"
	z.runner.left = float(config.lunge_recovery)
	z.runner.distance = 0.0
	z.runner.retry = float(config.lunge_cooldown)
	z.cooldown = maxf(float(z.cooldown), float(config.cooldown))


## True means this fixed step belongs to the special, including its harmless recovery.
static func step(world: RefCounted, z: Dictionary, target: Dictionary, dt: float) -> bool:
	if not ZombieTypes.charges(world.catalog, z):
		return false
	var state: Dictionary = z.runner
	var config: Dictionary = ZombieTypes.kind(world.catalog, z)
	state.retry = maxf(0.0, float(state.retry) - dt)
	if state.phase == "recover":
		state.left = maxf(0.0, float(state.left) - dt)
		if float(state.left) <= 0:
			state.phase = "idle"
		return true
	if state.phase == "tell":
		state.left = maxf(0.0, float(state.left) - dt)
		if float(state.left) <= 0:
			state.phase = "dash"
			state.distance = float(config.lunge_distance)
		return true
	if state.phase == "dash":
		_dash(world, z, dt)
		return true
	if not target.is_empty() and float(state.retry) <= 0 and float(z.cooldown) <= 0 and z.pos.distance_to(target.pos) <= float(config.lunge_range) and world.routes.line_clear(z.pos, target.pos):
		var direction: Vector2 = z.pos.direction_to(target.pos)
		if direction.is_zero_approx():
			direction = z.facing
		state.dx = direction.x
		state.dy = direction.y
		z.facing = direction
		state.phase = "tell"
		state.left = float(config.lunge_tell)
		return true
	return false


static func _dash(world: RefCounted, z: Dictionary, dt: float) -> void:
	var config: Dictionary = ZombieTypes.kind(world.catalog, z)
	var state: Dictionary = z.runner
	var direction := Vector2(float(state.dx), float(state.dy))
	var travel: float = minf(float(state.distance), float(config.lunge_speed) * dt)
	# Small straight samples cannot tunnel or slide along a fence like ordinary walking.
	while travel > 0.0001:
		var stride: float = minf(4.0, travel)
		var next: Vector2 = z.pos + direction * stride
		if not world.routes.walkable(next) or not world.routes.line_clear(z.pos, next):
			_recover(world, z)
			return
		for other: Dictionary in world.zombies:
			if other.id != z.id and float(other.hp) > 0 and next.distance_to(other.pos) < 22:
				_recover(world, z)
				return
		for person: Dictionary in [world.player] + world.survivors:
			if float(person.hp) > 0 and next.distance_to(person.pos) < 29 and world.routes.line_clear(z.pos, person.pos):
				var damage: float = float(config.damage)
				if Equipment.protected(world, person):
					damage *= float(world.balance.armour_damage_multiplier)
				if Equipment.shielded(world, person) and person.facing.dot(person.pos.direction_to(z.pos)) > 0.2:
					damage *= float(world.balance.shield_damage_multiplier)
				person.hp = maxf(0.0, float(person.hp) - damage)
				person.flash = 0.18
				_recover(world, z)
				return
		z.pos = next
		state.distance = maxf(0.0, float(state.distance) - stride)
		travel -= stride
	if float(state.distance) <= 0.0001:
		_recover(world, z)
