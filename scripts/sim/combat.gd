extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
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
	var weapon: Dictionary = Equipment.stats(world, attacker)
	attacker.cooldown = float(weapon.cooldown)
	attacker.swing = 0.18
	attacker.facing = direction
	var candidates: Array[Dictionary] = []
	for z: Dictionary in world.zombies:
		var offset: Vector2 = z.pos - attacker.pos
		if float(z.hp) <= 0 or offset.length() > float(weapon.reach):
			continue
		if direction.dot(offset.normalized()) < float(weapon.cone) or not world.routes.line_clear(attacker.pos, z.pos, true):
			continue
		candidates.append(z)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return attacker.pos.distance_squared_to(a.pos) < attacker.pos.distance_squared_to(b.pos))
	for i: int in range(mini(candidates.size(), int(weapon.targets))):
		var target: Dictionary = candidates[i]
		target.hp = maxf(0, float(target.hp) - float(weapon.damage))
		target.flash = 0.18
		target.cooldown = maxf(float(target.cooldown), 0.45)
		target.pos = world.routes.move(target.pos, target.pos + direction * float(weapon.knockback), float(weapon.knockback))



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
		world.player.pos = Routes.point(world.balance.home_respawn)
		world.move_input = Vector2.ZERO
		world.note("You were pulled back home. The street and your discoveries are preserved.")


static func _survivor(world: RefCounted, a: Dictionary, dt: float) -> void:
	var anchor: Vector2 = a.anchor
	match a.order:
		"Guard", "Home":
			anchor = Routes.point(world.balance.mara_start)
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
		if best < float(Equipment.stats(world, a).reach):
			strike(world, a, a.pos.direction_to(target.pos))
		elif a.order not in ["Guard", "Roadguard"] or (a.order == "Guard" and target.pos.y < 465):
			_walk(world, a, target.pos, dt, _survivor_speed(world, a))
		elif a.order == "Roadguard" and a.pos.distance_to(anchor) > 4:
			_walk(world, a, anchor, dt, _survivor_speed(world, a))
		return
	# A low barricade allows a gate guard to hit the attacker leaning over it.
	if a.order == "Guard" and not world.properties.home.open:
		for z: Dictionary in world.zombies:
			if float(z.hp) > 0 and z.pos.distance_to(Vector2(360, 490)) < 50 and a.pos.distance_to(Routes.point(world.balance.mara_start)) < 32 and float(a.cooldown) <= 0:
				z.hp = maxf(0, float(z.hp) - float(Equipment.stats(world, a).damage))
				z.flash = 0.18
				a.swing = 0.18
				a.facing = a.pos.direction_to(z.pos)
				a.cooldown = float(Equipment.stats(world, a).cooldown)
				a.activity = "Holding the barricade"
				return
	if a.order in ["Build", "Garden", "Workshop", "Roadwork", "Passage"] and danger(world, anchor, 170):
		anchor = Routes.point(world.balance.home_respawn)
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
	var productive: bool = (a.order == "Garden" and world.garden_done) or (a.order == "Workshop" and world.workshop.done)
	if productive and not a.activity.begins_with("Sheltering"):
		if not world.safe_connected(a.job):
			a.activity = "Work paused - secure the physical home route"
			return
		if a.pos.distance_to(anchor) > 24:
			var areas: Array[Rect2] = Neighbourhood.work_areas(world)
			var next: Vector2 = anchor if world.routes.safe_travel_clear(a.pos, anchor, areas) else world.routes.safe_waypoint(a.pos, anchor, areas)
			if next.is_equal_approx(a.pos):
				a.activity = "No safe work route - bring this person inside"
				return
			_walk(world, a, next, dt, _survivor_speed(world, a))
		return
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
	# Nearby living people override wandering, even during an unfinished roam heading.
	var target: Dictionary = {}
	var best: float = float(world.balance.zombie_notice_range)
	for a: Dictionary in [world.player] + world.survivors:
		var distance: float = z.pos.distance_to(a.pos)
		if float(a.hp) > 0 and distance < best:
			target = a
			best = distance
	if not target.is_empty() and best < 29.0 and world.routes.line_clear(z.pos, target.pos) and float(z.cooldown) <= 0:
		target.hp = maxf(0.0, float(target.hp) - incoming_damage(world, target, z.pos))
		target.flash = 0.18
		z.cooldown = float(world.balance.zombie_cooldown)
		return
	if float(z.cooldown) < 0.7:
		if target.is_empty():
			Wandering.step(world, z, dt)
		else:
			Wandering.advance(world, z, target.pos, dt)


static func _survivor_speed(world: RefCounted, a: Dictionary) -> float:
	return float(world.balance.survivor_speed) * Equipment.speed(world, a)


static func incoming_damage(world: RefCounted, target: Dictionary, source: Vector2) -> float:
	var damage: float = float(world.balance.zombie_damage)
	if Equipment.protected(world, target):
		damage *= float(world.balance.armour_damage_multiplier)
	if Equipment.shielded(world, target) and target.facing.dot(target.pos.direction_to(source)) > 0.2:
		damage *= float(world.balance.shield_damage_multiplier)
	return damage
