extends RefCounted
const Wandering = preload("res://scripts/sim/wandering.gd")
## Spatial combat and bounded AI. Every actor stays active off camera.

static func danger(world: RefCounted, pos: Vector2, radius: float) -> bool:
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and pos.distance_to(z.pos) < radius:
			return true
	return false


static func strike(world: RefCounted, attacker: Dictionary, direction: Vector2) -> void:
	if float(attacker.cooldown) > 0 or float(attacker.hp) <= 0:
		return
	if direction.is_zero_approx():
		direction = attacker.facing
	direction = direction.normalized()
	attacker.cooldown = float(world.balance.attack_cooldown)
	attacker.swing = 0.18
	attacker.facing = direction
	var target: Dictionary = {}
	var nearest: float = INF
	for z: Dictionary in world.zombies:
		var offset: Vector2 = z.pos - attacker.pos
		if float(z.hp) <= 0 or offset.length() > float(world.balance.attack_reach):
			continue
		if direction.dot(offset.normalized()) < float(world.balance.attack_cone_dot) or not world.routes.line_clear(attacker.pos, z.pos, true):
			continue
		if offset.length_squared() < nearest:
			nearest = offset.length_squared()
			target = z
	if not target.is_empty():
		target.hp = maxf(0, float(target.hp) - float(world.balance.melee_damage))
		target.flash = 0.18
		target.cooldown = maxf(float(target.cooldown), 0.45)
		target.pos = world.routes.move(target.pos, target.pos + direction * 18, 18)


static func step(world: RefCounted, dt: float) -> void:
	for a: Dictionary in world.survivors:
		if float(a.hp) <= 0:
			if a.activity != "Down - rest at home to recover":
				world.note(a.name + " is down. Rest at the safe home porch to recover the team.")
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
		"Build", "Garden", "Workshop":
			anchor = world.routes.point(world.definition(a.job).site)
	var target: Dictionary = {}
	var best: float = 150 if a.order != "Engage" else 220
	for z: Dictionary in world.zombies:
		var distance: float = a.pos.distance_to(z.pos)
		if float(z.hp) > 0 and distance < best and z.pos.distance_to(anchor) < 180 and world.routes.line_clear(a.pos, z.pos, true):
			target = z
			best = distance
	if not target.is_empty():
		a.activity = "Defending"
		if best < float(world.balance.attack_reach):
			strike(world, a, a.pos.direction_to(target.pos))
		elif a.order not in ["Guard", "Roadguard"] or (a.order == "Guard" and target.pos.y < 465):
			_walk(world, a, target.pos, dt, _survivor_speed(world, a))
		elif a.order == "Roadguard" and a.pos.distance_to(anchor) > 4:
			_walk(world, a, anchor, dt, _survivor_speed(world, a))
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
	if a.order in ["Build", "Garden", "Workshop", "Roadwork", "Passage"] and danger(world, anchor, 170):
		anchor = Vector2(360, 350)
		a.activity = "Sheltering - work preserved"
	else:
		a.activity = a.order
		match a.order:
			"Build":
				a.activity = "Working " + a.job
			"Garden":
				a.activity = "Tending garden" if world.garden_done else "Building garden"
			"Workshop":
				a.activity = "Workshop work" if (world.workshop.started and not world.workshop.done) or (world.workshop.armour_started and not world.workshop.armour_done) else "Workshop ready - approve next job"
				if world.workshop.armour_done:
					a.activity = "Workshop work complete"
			"Passage":
				a.activity = "Passage build/repair"
			"Roadwork":
				a.activity = "Road defence work"
	if a.pos.distance_to(anchor) > (4.0 if a.order == "Roadguard" else 24.0):
		var old: Vector2 = a.pos
		_walk(world, a, anchor, dt, _survivor_speed(world, a))
		if old.is_equal_approx(a.pos):
			a.activity = "Route blocked - check gate"
	elif a.order == "Home":
		a.order = "Guard"
		a.activity = "Guard"


static func _walk(world: RefCounted, a: Dictionary, target: Vector2, dt: float, speed: float) -> void:
	var next: Vector2 = target if world.routes.travel_clear(a.pos, target) else world.routes.waypoint(a.pos, target)
	if float(a.swing) <= 0:
		a.facing = a.pos.direction_to(next)
	a.pos = world.routes.move(a.pos, next, speed * dt)


static func _zombie(world: RefCounted, z: Dictionary, dt: float) -> void:
	# Bite only someone physically within reach. People never set movement goals.
	var target: Dictionary = {}
	var best: float = 29.0
	for a: Dictionary in [world.player] + world.survivors:
		var distance: float = z.pos.distance_to(a.pos)
		if float(a.hp) > 0 and distance < best and world.routes.line_clear(z.pos, a.pos):
			target = a
			best = distance
	if not target.is_empty() and float(z.cooldown) <= 0:
		target.hp = maxf(0.0, float(target.hp) - incoming_damage(world, target, z.pos))
		target.flash = 0.18
		z.cooldown = float(world.balance.zombie_cooldown)
		return
	if float(z.cooldown) < 0.7:
		Wandering.step(world, z, dt)


static func _survivor_speed(world: RefCounted, a: Dictionary) -> float:
	var factor: float = float(world.balance.armour_speed_multiplier) if a.id == "paige" and world.workshop.equipped else 1.0
	return float(world.balance.survivor_speed) * factor


static func incoming_damage(world: RefCounted, target: Dictionary, source: Vector2) -> float:
	var damage: float = float(world.balance.zombie_damage)
	if target.id == "paige" and world.workshop.equipped:
		damage *= float(world.balance.armour_damage_multiplier)
		if target.facing.dot(target.pos.direction_to(source)) > 0.2:
			damage *= float(world.balance.shield_damage_multiplier)
	return damage
