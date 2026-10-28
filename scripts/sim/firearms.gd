extends RefCounted
const Screecher = preload("res://scripts/sim/screecher.gd")
const Acoustics = preload("res://scripts/sim/noise.gd")
const Runner = preload("res://scripts/sim/runner.gd")
## Pistol ownership, physical ray shots and one shared ammunition workbench.
const Roster = preload("res://scripts/sim/roster.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Production = preload("res://scripts/sim/production.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func initial() -> Dictionary:
	return {"owned": false, "bullets": 0}


static func civilian(a: Dictionary) -> bool:
	return a.id == "ellis"


static func rescue(world: RefCounted) -> void:
	if not Roster.recruit(world, "ellis"):
		return
	world.firearms.owned = true
	world.firearms.bullets = int(world.catalog.firearm.gift_bullets)
	# Rescue dialogue comes from the authored roster.


static func shoot(world: RefCounted) -> bool:
	if not str(world.carry.patient).is_empty() or not world.firearms.owned or float(world.player.hp) <= 0 or float(world.player.cooldown) > 0:
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
	Acoustics.emit(world, world.player.id, "pistol", origin)
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
		Runner.interrupt(world, target)
		Screecher.interrupt(world, target)
		target.cooldown = maxf(float(target.cooldown), 0.45)
		endpoint = origin + direction * nearest
	world.shot = {"from": origin, "to": endpoint, "left": 0.12}
	return true


static func batch(world: RefCounted) -> Dictionary:
	return WorkOrders.current(world, "munitions")


static func progress(world: RefCounted) -> float:
	var order: Dictionary = batch(world)
	return float(order.work_done) if WorkOrders.pending(order) else 0.0


static func reserved(world: RefCounted) -> bool:
	return WorkOrders.pending(batch(world))


static func step(world: RefCounted, dt: float) -> void:
	var site: Vector2 = Routes.point(world.definition("munitions").site)
	var reason: String = ""
	if not world.properties.munitions.claimed:
		reason = "Reclaim site"
	elif not world.safe_connected("munitions"):
		reason = "Secure home route"
	elif world.remaining("munitions") > 0:
		reason = "Clear nearby threats"
	var executor: String = ""
	for a: Dictionary in world.survivors:
		if a.order == "Ammo" and float(a.hp) > 0 and a.pos.distance_to(site) < 40 and not a.activity.begins_with("Sheltering") and a.duty.clear_left <= 0:
			if executor.is_empty() or str(a.id) < executor:
				executor = a.id
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and z.pos.distance_to(site) < 170:
			reason = "Clear nearby threats"
	if reason.is_empty() and executor.is_empty():
		reason = "Need worker at bench"
	if not reason.is_empty():
		world.production.reason = reason
		WorkOrders.block(world, "munitions", reason)
		return
	var rules: Dictionary = world.catalog.firearm
	var recipe: Dictionary = WorkRecipes.recipe(world.catalog, "bullets")
	if not reserved(world):
		world.production.reason = Production.start_reason(world)
		if not world.production.reason.is_empty():
			return
		if not WorkOrders.approve(world, "munitions", "munitions", recipe, site):
			return
	world.production.reason = ""
	if WorkOrders.advance(world, "munitions", executor, dt):
		if world.production.mode == "once":
			world.production.mode = "stopped"
		world.note("Ammunition workshop: %d bullets crafted." % int(rules.batch_bullets))
