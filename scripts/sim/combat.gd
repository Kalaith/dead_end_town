extends RefCounted
const Screecher = preload("res://scripts/sim/screecher.gd")
const Spitter = preload("res://scripts/sim/spitter.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Acoustics = preload("res://scripts/sim/noise.gd")
const Runner = preload("res://scripts/sim/runner.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Wandering = preload("res://scripts/sim/wandering.gd")
const Raiding = preload("res://scripts/sim/raiding.gd")
## Spatial combat and bounded AI. Every actor stays active off camera.

static func danger(world: RefCounted, pos: Vector2, radius: float) -> bool:
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and pos.distance_to(z.pos) < radius:
			return true
	return false


static func strike(world: RefCounted, attacker: Dictionary, direction: Vector2) -> void:
	if Firearms.civilian(attacker) or (attacker.id == "you" and not str(world.carry.patient).is_empty()) or (world.rescue_jobs.has(attacker.id) and world.rescue_jobs[attacker.id].phase == "carry"):
		return
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
		Runner.interrupt(world, target)
		Screecher.interrupt(world, target)
		Spitter.interrupt(world, target)
		target.cooldown = maxf(float(target.cooldown), 0.45)
		target.pos = world.routes.move(target.pos, target.pos + direction * float(weapon.knockback), float(weapon.knockback))
	if not candidates.is_empty():
		Acoustics.emit(world, attacker.id, "impact", attacker.pos)



static func step(world: RefCounted, dt: float) -> void:
	for a: Dictionary in world.survivors:
		if float(a.hp) <= 0:
			if a.activity != "Down - carry to shelter":
				world.note(a.name + " is down. Carry them to a clear shelter.")
			a.activity = "Down - carry to shelter"
			continue
		if a.order not in ["Rescue", "Field"]:
			_survivor(world, a, dt)
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0:
			_zombie(world, z, dt)
			if float(world.player.hp) <= 0:
				return
	Spitter.advance(world, dt)
	Raiding.sweep(world)


static func _survivor(world: RefCounted, a: Dictionary, dt: float) -> void:
	var previous: String = a.activity
	var anchor: Vector2 = a.anchor
	match a.order:
		"Guard", "Home":
			anchor = Routes.point(world.balance.mara_start)
		"Follow", "Engage":
			anchor = world.player.pos + Vector2(-38, 24)
		"Build", "Garden", "Workshop", "Ammo":
			anchor = world.routes.point(world.definition(a.job).site)
	var target: Dictionary = {}
	var best: float = 150 if a.order != "Engage" else 220
	for z: Dictionary in world.zombies:
		var distance: float = a.pos.distance_to(z.pos)
		if not Firearms.civilian(a) and float(z.hp) > 0 and distance < best and z.pos.distance_to(anchor) < 180 and world.routes.line_clear(a.pos, z.pos, true):
			target = z
			best = distance
	if not target.is_empty():
		# A badly hurt fighter gives ground instead of trading blows to the knockout.
		if float(a.hp) < float(world.balance.survivor_health) * 0.4 and best < 90:
			a.activity = "Falling back"
			var retreat: Vector2 = a.pos + target.pos.direction_to(a.pos) * 120.0
			_walk(world, a, retreat if world.routes.walkable(retreat) else Routes.point(world.balance.home_respawn), dt, _survivor_speed(world, a))
			return
		a.activity = "Defending"
		if best < float(Equipment.stats(world, a).reach):
			strike(world, a, a.pos.direction_to(target.pos))
		elif a.order not in ["Guard", "Roadguard"] or (a.order == "Guard" and target.pos.y < 465):
			_walk(world, a, target.pos, dt, _survivor_speed(world, a))
		elif a.order == "Roadguard" and a.pos.distance_to(anchor) > 4:
			_walk(world, a, anchor, dt, _survivor_speed(world, a))
		return
	# A low barricade allows a gate guard to hit the attacker leaning over it.
	if not Firearms.civilian(a) and a.order == "Guard" and not world.properties.home.open:
		for z: Dictionary in world.zombies:
			if float(z.hp) > 0 and z.pos.distance_to(Vector2(360, 490)) < 50 and a.pos.distance_to(Routes.point(world.balance.mara_start)) < 32 and float(a.cooldown) <= 0:
				z.hp = maxf(0, float(z.hp) - float(Equipment.stats(world, a).damage))
				z.flash = 0.18
				Runner.interrupt(world, z)
				Screecher.interrupt(world, z)
				Spitter.interrupt(world, z)
				Acoustics.emit(world, a.id, "impact", a.pos)
				a.swing = 0.18
				a.facing = a.pos.direction_to(z.pos)
				a.cooldown = float(Equipment.stats(world, a).cooldown)
				a.activity = "Holding the barricade"
				return
	if (a.order in ["Build", "Garden", "Workshop", "Roadwork", "Passage", "Repair", "Ammo", "Clinic", "Greenhouse"] and (danger(world, anchor, 170) or a.duty.clear_left > 0)) or (Firearms.civilian(a) and danger(world, a.pos, 170)):
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
			"Greenhouse":
				a.activity = "Tending greenhouse" if world.greenhouse.done else "Restoring greenhouse"
			"Clinic":
				a.activity = "Treating at clinic" if world.clinic.done else "Restoring clinic"
			"Ammo":
				a.activity = "Crafting bullets" if Firearms.reserved(world) else "Bullet bench"
				if not world.production.reason.is_empty():
					a.activity = world.production.reason
				if not Facility.state(world, "munitions").claimed or not world.safe_connected("munitions"):
					a.activity = "Bullet crafting paused - reclaim the workshop route"
					anchor = Routes.point(world.balance.home_respawn)
			"Passage":
				a.activity = "Passage build/repair"
			"Roadwork":
				a.activity = "Road defence work"
	if a.order in ["Build", "Garden", "Workshop", "Roadwork", "Passage", "Repair", "Ammo", "Clinic", "Greenhouse"] and a.duty.retry > 0 and not a.activity.begins_with("Sheltering"):
		a.activity = previous
		return
	var productive: bool = (a.order == "Greenhouse" and world.greenhouse.done) or (a.order == "Garden" and world.garden_done) or (a.order == "Workshop" and world.workshop.done) or a.order == "Ammo" or (a.order == "Clinic" and world.clinic.done)
	if productive and not a.activity.begins_with("Sheltering"):
		if not world.safe_connected(a.job):
			a.activity = "Work paused - secure the physical home route"
			return
		if a.pos.distance_to(anchor) > 24:
			var areas: Array[Rect2] = Neighbourhood.work_areas(world)
			var next: Vector2 = anchor if world.routes.safe_travel_clear(a.pos, anchor, areas) else world.routes.safe_waypoint(a.pos, anchor, areas)
			if next.is_equal_approx(a.pos):
				a.activity = "No safe work route - bring this person inside"
				a.duty.retry = float(world.balance.work_retry_seconds)
				return
			_walk(world, a, next, dt, _survivor_speed(world, a))
		return
	if a.pos.distance_to(anchor) > (4.0 if a.order == "Roadguard" else 24.0):
		var old: Vector2 = a.pos
		_walk(world, a, anchor, dt, _survivor_speed(world, a))
		if old.is_equal_approx(a.pos) and not a.activity.begins_with("Sheltering"):
			a.activity = "Route blocked - check gate"
			a.duty.retry = float(world.balance.work_retry_seconds)
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
	var best: float = float(ZombieTypes.kind(world.catalog, z).get("notice_range", world.balance.zombie_notice_range))
	for a: Dictionary in [world.player] + world.survivors:
		var distance: float = z.pos.distance_to(a.pos)
		if float(a.hp) > 0 and (distance < best or (not target.is_empty() and distance == best and str(a.id) < str(target.id))):
			target = a
			best = distance
	var guard: bool = Boss.guards(world, z)
	if guard:
		target = Boss.leashed(world, target)
	Acoustics.observe(world, z, target)
	if Runner.step(world, z, target, dt):
		return
	if Screecher.step(world, z, target, dt):
		return
	if Spitter.step(world, z, target, dt):
		return
	if not target.is_empty() and best < 29.0 and world.routes.line_clear(z.pos, target.pos) and float(z.cooldown) <= 0 and not (target.id == "you" and Vehicle.driving(world)):
		target.hp = maxf(0.0, float(target.hp) - incoming_damage(world, target, z.pos, z))
		target.flash = 0.18
		z.cooldown = ZombieTypes.stat(world.catalog, z, "cooldown")
		return
	if float(z.cooldown) < 0.7:
		if guard and target.is_empty():
			Boss.return_to_post(world, z, dt)
		elif target.is_empty():
			var investigation: Dictionary = Acoustics.destination(world, z)
			if not investigation.is_empty():
				var point: Vector2 = investigation.position
				if z.pos.distance_to(point) > 12:
					var next: Vector2 = point if world.routes.travel_clear(z.pos, point) else world.routes.waypoint(z.pos, point)
					# If no path is open, approach the obstruction physically.
					Wandering.advance(world, z, point if next.is_equal_approx(z.pos) else next, dt)
			elif z.raid:
				Raiding.step(world, z, dt)
			else:
				Wandering.step(world, z, dt)
		elif not Spitter.holds(world, z, target):
			Wandering.advance(world, z, target.pos, dt)


static func _survivor_speed(world: RefCounted, a: Dictionary) -> float:
	return float(world.balance.survivor_speed) * Equipment.speed(world, a)


static func incoming_damage(world: RefCounted, target: Dictionary, source: Vector2, attacker: Dictionary = {}) -> float:
	var damage: float = ZombieTypes.stat(world.catalog, attacker, "damage")
	if Equipment.protected(world, target):
		damage *= float(world.balance.armour_damage_multiplier)
	if Equipment.shielded(world, target) and target.facing.dot(target.pos.direction_to(source)) > 0.2:
		damage *= float(world.balance.shield_damage_multiplier)
	return damage
