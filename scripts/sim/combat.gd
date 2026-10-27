extends RefCounted
## Spatial combat and bounded AI. Every actor stays active off camera.

static func danger(world: RefCounted, pos: Vector2, radius: float) -> bool:
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and pos.distance_to(z.pos) < radius:
			return true
	return false


static func strike(world: RefCounted, attacker: Dictionary, direction: Vector2) -> void:
	if float(attacker.cooldown) > 0 or float(attacker.hp) <= 0:
		return
	attacker.cooldown = float(world.balance.attack_cooldown)
	attacker.swing = 0.18
	attacker.facing = direction
	for z: Dictionary in world.zombies:
		var offset: Vector2 = z.pos - attacker.pos
		if float(z.hp) <= 0 or offset.length() > float(world.balance.attack_reach):
			continue
		if direction.dot(offset.normalized()) < 0.2 or not world.routes.line_clear(attacker.pos, z.pos):
			continue
		z.hp = maxf(0, float(z.hp) - float(world.balance.melee_damage))
		z.flash = 0.18
		z.cooldown = maxf(float(z.cooldown), 0.45)
		z.pos = world.routes.move(z.pos, z.pos + direction * 18, 18)


static func step(world: RefCounted, dt: float) -> void:
	for a: Dictionary in world.survivors:
		if float(a.hp) <= 0:
			a.activity = "Down - rest at home to recover"
			continue
		_survivor(world, a, dt)
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0:
			_zombie(world, z, dt)
	if float(world.player.hp) <= 0:
		world.downs += 1
		world.player.hp = float(world.balance.player_health)
		world.player.pos = Vector2(360, 350)
		world.move_input = Vector2.ZERO
		world.note("You were pulled back home. The street and your discoveries are preserved.")


static func _survivor(world: RefCounted, a: Dictionary, dt: float) -> void:
	var anchor: Vector2 = a.anchor
	match a.order:
		"Guard", "Home":
			anchor = Vector2(360, 445)
		"Follow", "Engage":
			anchor = world.player.pos + Vector2(-38, 24)
		"Build":
			anchor = world.routes.point(world.definition("garden").site)
	var target: Dictionary = {}
	var best: float = 150 if a.order != "Engage" else 220
	for z: Dictionary in world.zombies:
		var distance: float = a.pos.distance_to(z.pos)
		if float(z.hp) > 0 and distance < best and z.pos.distance_to(anchor) < 180 and world.routes.line_clear(a.pos, z.pos):
			target = z
			best = distance
	if not target.is_empty():
		a.activity = "Defending"
		if best < float(world.balance.attack_reach):
			strike(world, a, a.pos.direction_to(target.pos))
		elif a.order != "Guard" or target.pos.y < 465:
			_walk(world, a, target.pos, dt, float(world.balance.survivor_speed))
		return
	# A low barricade allows a gate guard to hit the attacker leaning over it.
	if a.order == "Guard" and not world.properties.home.open:
		for z: Dictionary in world.zombies:
			if float(z.hp) > 0 and z.pos.distance_to(Vector2(360, 490)) < 50 and a.pos.distance_to(Vector2(360, 445)) < 32 and float(a.cooldown) <= 0:
				z.hp = maxf(0, float(z.hp) - float(world.balance.melee_damage))
				z.flash = 0.18
				a.swing = 0.18
				a.facing = a.pos.direction_to(z.pos)
				a.cooldown = float(world.balance.attack_cooldown)
				a.activity = "Holding the barricade"
				return
	if a.order == "Build" and danger(world, anchor, 170):
		anchor = Vector2(360, 350)
		a.activity = "Sheltering - work preserved"
	else:
		a.activity = "Working garden" if a.order == "Build" else a.order
	if a.pos.distance_to(anchor) > 24:
		var old: Vector2 = a.pos
		_walk(world, a, anchor, dt, float(world.balance.survivor_speed))
		if old.is_equal_approx(a.pos):
			a.activity = "Route blocked - check gate"


static func _walk(world: RefCounted, a: Dictionary, target: Vector2, dt: float, speed: float) -> void:
	var next: Vector2 = target if world.routes.line_clear(a.pos, target) else world.routes.waypoint(a.pos, target)
	a.facing = a.pos.direction_to(next)
	a.pos = world.routes.move(a.pos, next, speed * dt)


static func _zombie(world: RefCounted, z: Dictionary, dt: float) -> void:
	var target: Dictionary = {}
	var best: float = float(world.balance.awareness)
	for a: Dictionary in [world.player] + world.survivors:
		var distance: float = z.pos.distance_to(a.pos)
		if float(a.hp) > 0 and distance < best and world.routes.line_clear(z.pos, a.pos):
			target = a
			best = distance
	if not target.is_empty():
		if best < 29 and float(z.cooldown) <= 0:
			target.hp = maxf(0, float(target.hp) - float(world.balance.zombie_damage))
			target.flash = 0.18
			z.cooldown = float(world.balance.zombie_cooldown)
		elif best > 26 and float(z.cooldown) < 0.7:
			_walk(world, z, target.pos, dt, float(world.balance.zombie_speed))
		return
	if z.raid:
		var gate := Vector2(360, 500)
		if world.properties.home.open or float(world.properties.home.gate_hp) <= 0:
			gate = Vector2(360, 350)
		if z.pos.distance_to(gate) < 30 and float(z.cooldown) <= 0 and float(world.properties.home.gate_hp) > 0 and not world.properties.home.open:
			world.properties.home.gate_hp = maxf(0, float(world.properties.home.gate_hp) - float(world.balance.gate_damage))
			z.cooldown = float(world.balance.zombie_cooldown)
			if float(world.properties.home.gate_hp) <= 0:
				world.rebuild_routes()
				world.note("HOME / Gate breached. Return to defend and rebuild.")
		else:
			_walk(world, z, gate, dt, float(world.balance.zombie_speed))
