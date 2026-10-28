extends RefCounted
## Idle wandering and local pursuit share physical collision and defence damage.
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")


static func step(world: RefCounted, z: Dictionary, dt: float) -> void:
	z.roam_left = maxf(0.0, float(z.roam_left) - dt)
	if float(z.roam_left) <= 0:
		z.roam_angle = world.roam_rng.randf_range(-PI, PI)
		z.roam_left = world.roam_rng.randf_range(float(world.balance.roam_turn_min), float(world.balance.roam_turn_max))
	advance(world, z, z.pos + Vector2.from_angle(float(z.roam_angle)) * 100.0, dt)


static func advance(world: RefCounted, z: Dictionary, target: Vector2, dt: float) -> void:
	var direction: Vector2 = z.pos.direction_to(target)
	z.facing = direction
	var travel: float = ZombieTypes.stat(world.catalog, z, "speed") * dt
	var intended: Vector2 = z.pos + direction * travel
	var next: Vector2 = world.routes.move(z.pos, intended, travel)
	if next.distance_to(z.pos) < travel * 0.5:
		_bump(world, z, intended, direction, dt)
		# Choose a fresh heading next step instead of sticking to a wall or porch.
		z.roam_left = 0.0
	z.pos = next


static func _bump(world: RefCounted, z: Dictionary, intended: Vector2, direction: Vector2, dt: float) -> void:
	if Roadworks.intercept(world, z, z.pos + direction * float(world.balance.barricade_attack_reach) * 2, dt):
		return
	if Neighbourhood.bump(world, z, intended):
		return
	for p: Dictionary in world.catalog.properties:
		var state: Dictionary = world.properties[p.id]
		if state.open or float(state.gate_hp) <= 0:
			continue
		var gate: Vector2 = Routes.point(p.gate)
		var fence_y: float = gate.y if gate.y == float(p.rect[1]) else gate.y - 8
		var collision := Rect2(gate.x - 44, fence_y, 88, 8).grow(Routes.RADIUS)
		if collision.has_point(intended) and float(z.cooldown) <= 0:
			state.gate_hp = maxf(0.0, float(state.gate_hp) - float(world.balance.gate_damage))
			z.cooldown = ZombieTypes.stat(world.catalog, z, "cooldown")
			if float(state.gate_hp) <= 0:
				world.rebuild_routes()
				world.note(p.name + " / Gate breached. Defend and rebuild.")
			return
