extends RefCounted
## Temporary street defences. All work, damage and salvage are authoritative.
const Repairs = preload("res://scripts/sim/repairs.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func empty() -> Dictionary:
	return {"phase": "empty", "progress": 0.0, "hp": 0.0, "repair_reserved": false}


static func initial(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for d: Dictionary in catalog.barricades:
		result[d.id] = empty()
	return result


static func unlocked(world: RefCounted, d: Dictionary) -> bool:
	for id: String in d.requires:
		if not world.properties[id].claimed or not world.connected(id):
			return false
	return true


static func nearby(world: RefCounted) -> Dictionary:
	for d: Dictionary in world.catalog.barricades:
		if world.player.pos.distance_to(Routes.point(d.center)) < float(world.balance.barricade_work_range):
			return d
	return {}


static func active(state: Dictionary) -> bool:
	return state.phase in ["ready", "dismantling"] and float(state.hp) > 0


static func danger(world: RefCounted, d: Dictionary) -> bool:
	var rect: Rect2 = Routes.rectangle(d.rect).grow(float(world.balance.barricade_danger_range))
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and rect.has_point(z.pos):
			return true
	return false


static func salvage(world: RefCounted, state: Dictionary) -> int:
	var cost: float = float(world.balance.barricade_cost)
	var rate: float = float(world.balance.barricade_salvage)
	if state.phase == "building":
		return int(floor(cost * lerpf(1.0, rate, float(state.progress) / float(world.balance.barricade_seconds))))
	return int(floor(cost * rate * float(state.hp) / float(world.balance.barricade_health)))


static func context(world: RefCounted, d: Dictionary) -> String:
	var s: Dictionary = world.roadworks[d.id]
	if not unlocked(world, d):
		return "Secure both yards"
	match s.phase:
		"empty":
			return "E Barricade · %d materials" % int(world.balance.barricade_cost)
		"building":
			if float(s.progress) >= float(world.balance.barricade_seconds) and _occupied(world, Routes.rectangle(d.rect)):
				return "Clear work area"
			return "R Build   E Cancel (+%d)" % salvage(world, s)
		"dismantling":
			return "R Remove (+%d)   E Keep" % salvage(world, s)
	var repair: String = "   R Repair · %d materials" % int(world.balance.barricade_repair_cost) if float(s.hp) < float(world.balance.barricade_health) else ""
	return "E Remove (+%d)%s   G Guard" % [salvage(world, s), repair]


static func interact(world: RefCounted, d: Dictionary) -> void:
	if float(world.player.hp) <= 0 or nearby(world).get("id") != d.id:
		return
	var s: Dictionary = world.roadworks[d.id]
	if not unlocked(world, d):
		world.note("Secure both properties facing this stretch of road before fortifying it.")
		return
	if danger(world, d):
		world.note("Clear threats along the barricade before changing the defence.")
		return
	match s.phase:
		"empty":
			var cost: int = int(world.balance.barricade_cost)
			if not WorkOrders.approve(world, "road:" + str(d.id), d.id, WorkRecipes.recipe(world.catalog, "road_build"), Routes.point(d.site)):
				world.note("Road barricade needs %d materials; stockpile has %d." % [cost, world.materials])
				return
			s.phase = "building"
			world.note("%s committed. Hold R or assign a survivor with F." % d.name)
		"building", "dismantling":
			cancel(world, "road:" + str(d.id))
		"ready":
			if not WorkOrders.approve(world, "road:" + str(d.id), d.id, WorkRecipes.recipe(world.catalog, "road_remove"), Routes.point(d.site)):
				world.note("Finish a project before approving more work.")
				return
			Repairs.destroy(world, "road:" + str(d.id))
			s.phase = "dismantling"
			s.progress = 0.0
			s.repair_reserved = false
			world.note("Removal approved. Hold R or assign a worker.")


static func cancel(world: RefCounted, socket: String) -> bool:
	if not socket.begins_with("road:"):
		return false
	var id: String = socket.trim_prefix("road:")
	if not world.roadworks.has(id):
		return false
	var s: Dictionary = world.roadworks[id]
	if s.phase not in ["building", "dismantling"] or not WorkOrders.cancel(world, socket):
		return false
	if s.phase == "building":
		world.roadworks[id] = empty()
	else:
		s.phase = "ready"
		s.progress = 0.0
	_release(world, id)
	world.note("Work cancelled. Barricade kept." if s.phase == "ready" else "Blueprint cancelled. Materials returned.")
	return true


static func assign(world: RefCounted, d: Dictionary, survivor_id: String = "mara") -> void:
	# Compatibility entry point; the live menu always supplies a survivor id.
	world.assign_survivor(survivor_id, "work:" + d.id)


static func guard_post(world: RefCounted, d: Dictionary) -> Vector2:
	var center: Vector2 = Routes.point(d.center)
	return center + center.direction_to(Routes.point(d.site)) * float(world.balance.barricade_stand_offset)


static func post_guard(world: RefCounted) -> void:
	var d: Dictionary = nearby(world)
	if d.is_empty() or not active(world.roadworks[d.id]):
		world.note("Stand near a completed road barricade to post a guard.")
		return
	var post: Vector2 = guard_post(world, d)
	var chosen: Dictionary = {}
	var best: float = INF
	for a: Dictionary in world.survivors:
		if a.id == "ellis":
			continue
		if float(a.hp) <= 0:
			continue
		if a.order == "Roadguard" and a.anchor.distance_to(post) < 10:
			world.note("%s already guards this barricade." % a.name)
			return
		var distance: float = a.pos.distance_to(post) + (10000.0 if a.order == "Roadguard" else 0.0)
		if distance < best:
			best = distance
			chosen = a
	if chosen.is_empty():
		world.note("No standing survivor is available to guard the road.")
		return
	chosen.job = ""
	chosen.order = "Roadguard"
	chosen.anchor = post
	chosen.duty.role = "guard:" + str(d.id)
	chosen.duty.anchor = [post.x, post.y]
	chosen.duty.temporary = false
	chosen.duty.return_task = ""
	world.note("%s: %s" % [chosen.name, d.name])


static func step(world: RefCounted, dt: float) -> void:
	for d: Dictionary in world.catalog.barricades:
		var s: Dictionary = world.roadworks[d.id]
		var socket: String = "road:" + str(d.id)
		if s.phase == "empty":
			continue
		if not unlocked(world, d) or danger(world, d):
			WorkOrders.block(world, socket, "Reclaim site" if not unlocked(world, d) else "Clear nearby threats")
			Repairs.block(world, "road:" + str(d.id), "Reclaim site" if not unlocked(world, d) else "Clear nearby threats")
			continue
		var executor: String = "you" if world.working and float(world.player.hp) > 0 and world.player.pos.distance_to(Routes.point(d.center)) < float(world.balance.barricade_work_range) else ""
		for a: Dictionary in world.survivors:
			if executor == "you":
				break
			if a.order == "Roadwork" and a.job == d.id and float(a.hp) > 0 and a.pos.distance_to(Routes.point(d.site)) < 40 and not a.activity.begins_with("Sheltering") and a.duty.clear_left <= 0 and (executor.is_empty() or str(a.id) < executor):
				executor = a.id
		if executor.is_empty():
			WorkOrders.block(world, socket, "Need worker at site")
			Repairs.block(world, "road:" + str(d.id), "Need worker at site")
			continue
		if s.phase == "ready":
			_repair(world, d, s, executor, dt)
			continue
		var removed: bool = s.phase == "dismantling"
		var completed: bool = WorkOrders.advance(world, socket, executor, dt, removed or not _occupied(world, Routes.rectangle(d.rect)))
		s.progress = float(WorkOrders.current(world, socket).work_done)
		if not completed:
			continue
		if removed:
			var refund: int = salvage(world, s)
			world.materials += refund
			world.roadworks[d.id] = empty()
			world.note("Road open. +%d materials." % refund)
		else:
			s.phase = "ready"
			s.hp = float(world.balance.barricade_health)
			s.progress = 0.0
			world.note("%s ready." % d.name)
		world.rebuild_routes()
		_release(world, d.id, removed)


static func _occupied(world: RefCounted, rect: Rect2) -> bool:
	for a: Dictionary in [world.player] + world.survivors + world.zombies:
		if (not a.has("raid") or float(a.hp) > 0) and rect.grow(Routes.RADIUS).has_point(a.pos):
			return true
	return false


static func _repair(world: RefCounted, d: Dictionary, s: Dictionary, executor: String, dt: float) -> void:
	if float(s.hp) >= float(world.balance.barricade_health) and not s.repair_reserved:
		_release(world, d.id)
		return
	if Repairs.step(world, "road:" + str(d.id), executor, dt):
		_release(world, d.id)


static func _release(world: RefCounted, id: String, remove_guard: bool = false) -> void:
	for a: Dictionary in world.survivors:
		if a.order == "Roadwork" and a.job == id:
			world.finish_job(a, true)
	if not remove_guard:
		return
	for d: Dictionary in world.catalog.barricades:
		if d.id == id:
			for a: Dictionary in world.survivors:
				if a.order == "Roadguard" and a.anchor.distance_to(guard_post(world, d)) < 10:
					world.assign_survivor(a.id, "hold" if a.id == "ellis" else "home", false)


static func intercept(world: RefCounted, z: Dictionary, target: Vector2, dt: float) -> bool:
	var chosen: Dictionary = {}
	var nearest: float = INF
	var hit: Vector2 = Vector2.ZERO
	for d: Dictionary in world.catalog.barricades:
		if not active(world.roadworks[d.id]):
			continue
		var rect: Rect2 = Routes.rectangle(d.rect)
		var x: float = rect.get_center().x
		if is_zero_approx(target.x - z.pos.x):
			continue
		var fraction: float = (x - z.pos.x) / (target.x - z.pos.x)
		if fraction <= 0 or fraction >= 1:
			continue
		var crossing: Vector2 = z.pos.lerp(target, fraction)
		if crossing.y < rect.position.y or crossing.y > rect.end.y:
			continue
		var distance: float = z.pos.distance_to(crossing)
		if distance < nearest:
			nearest = distance
			chosen = d
			hit = crossing
	if chosen.is_empty():
		return false
	var s: Dictionary = world.roadworks[chosen.id]
	if nearest < float(world.balance.barricade_attack_reach):
		if float(z.cooldown) <= 0:
			if float(s.hp) == float(world.balance.barricade_health):
				world.note("STREET / %s is under attack." % chosen.name)
			s.hp = maxf(0.0, float(s.hp) - float(world.balance.gate_damage) * ZombieTypes.stat(world.catalog, z, "breach"))
			z.cooldown = ZombieTypes.stat(world.catalog, z, "cooldown")
			if float(s.hp) <= 0:
				Repairs.destroy(world, "road:" + str(chosen.id))
				WorkOrders.cancel(world, "road:" + str(chosen.id), true)
				world.roadworks[chosen.id] = empty()
				_release(world, chosen.id, true)
				world.rebuild_routes()
				world.note("STREET / %s breached. The road is open." % chosen.name)
	else:
		var side: float = -1.0 if z.pos.x < hit.x else 1.0
		var stand: Vector2 = hit + Vector2(side * float(world.balance.barricade_stand_offset), 0)
		var next: Vector2 = stand if world.routes.line_clear(z.pos, stand) else world.routes.waypoint(z.pos, stand)
		z.facing = z.pos.direction_to(next)
		z.pos = world.routes.move(z.pos, next, ZombieTypes.stat(world.catalog, z, "speed") * dt)
	return true
