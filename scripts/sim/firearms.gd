extends RefCounted
## Pistol ownership, physical ray shots and one shared ammunition workbench.
const Routes = preload("res://scripts/sim/routes.gd")


static func initial() -> Dictionary:
	return {"owned": false, "bullets": 0, "progress": 0.0, "reserved": false}


static func civilian(a: Dictionary) -> bool:
	return a.id == "ellis"


static func rescue(world: RefCounted) -> void:
	var a: Dictionary = world.actor("ellis", "Ellis", Routes.point(world.definition("residence").site) + Vector2(35, 0), float(world.balance.survivor_health))
	a.order = "Follow"
	world.survivors.append(a)
	world.firearms.owned = true
	world.firearms.bullets = int(world.catalog.firearm.gift_bullets)
	world.note("Ellis rescued: 'Take my pistol and six bullets. I can work, but I can't fight or guard.' Right click to shoot; left click still swings.")


static func shoot(world: RefCounted) -> bool:
	if not world.firearms.owned or float(world.player.hp) <= 0 or float(world.player.cooldown) > 0:
		return false
	if int(world.firearms.bullets) <= 0:
		world.note("Pistol empty. Assign a worker at the ammunition workshop to craft bullets.")
		return false
	var rules: Dictionary = world.catalog.firearm
	var direction: Vector2 = world.aim.normalized()
	if direction.is_zero_approx():
		direction = world.player.facing
	world.player.facing = direction
	world.player.cooldown = float(rules.cooldown)
	world.firearms.bullets = int(world.firearms.bullets) - 1
	var origin: Vector2 = world.player.pos
	var endpoint: Vector2 = origin + direction * float(rules.range)
	# Sample the same solid geometry used by melee: closed gates and fences stop shots.
	for distance: int in range(1, ceili(float(rules.range)) + 1):
		var point: Vector2 = origin + direction * distance
		if not world.routes.line_clear(origin, point, true):
			endpoint = origin + direction * (distance - 1)
			break
	var target: Dictionary = {}
	var nearest: float = origin.distance_to(endpoint)
	for z: Dictionary in world.zombies:
		var offset: Vector2 = z.pos - origin
		var along: float = offset.dot(direction)
		if float(z.hp) > 0 and along >= 0 and along <= nearest and absf(offset.cross(direction)) <= float(rules.hit_radius) and world.routes.line_clear(origin, z.pos, true):
			target = z
			nearest = along
	if not target.is_empty():
		target.hp = maxf(0.0, float(target.hp) - float(rules.damage))
		target.flash = 0.18
		target.cooldown = maxf(float(target.cooldown), 0.45)
		endpoint = origin + direction * nearest
	world.shot = {"from": origin, "to": endpoint, "left": 0.12}
	return true


static func step(world: RefCounted, dt: float) -> void:
	var site: Vector2 = Routes.point(world.definition("munitions").site)
	if not world.properties.munitions.claimed or not world.connected("munitions") or world.remaining("munitions") > 0:
		return
	var executor: bool = false
	for a: Dictionary in world.survivors:
		if a.order == "Ammo" and float(a.hp) > 0 and a.pos.distance_to(site) < 40 and not a.activity.begins_with("Sheltering"):
			executor = true
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and z.pos.distance_to(site) < 170:
			return
	if not executor:
		return
	var rules: Dictionary = world.catalog.firearm
	if not world.firearms.reserved:
		if world.materials < int(rules.material_cost):
			return
		world.materials -= int(rules.material_cost)
		world.firearms.reserved = true
	world.firearms.progress = minf(float(rules.craft_seconds), float(world.firearms.progress) + dt)
	if float(world.firearms.progress) >= float(rules.craft_seconds):
		world.firearms.bullets = int(world.firearms.bullets) + int(rules.batch_bullets)
		world.firearms.progress = 0.0
		world.firearms.reserved = false
		world.note("Ammunition workshop: %d bullets crafted." % int(rules.batch_bullets))
