extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")


static func initial() -> Dictionary:
	return {"started": false, "done": false, "progress": 0.0, "patients": {}}


static func site(world: RefCounted) -> Vector2:
	return Routes.point(world.definition("clinic").site)


static func reason(world: RefCounted, productive: bool = true) -> String:
	if not world.properties.clinic.claimed:
		return "Reclaim clinic"
	if world.remaining("clinic") > 0 or Combat.danger(world, site(world), 170):
		return "Clear nearby threats"
	if productive and not world.safe_connected("clinic"):
		return "Secure home route"
	return ""


static func approve(world: RefCounted) -> bool:
	if world.clinic.started or not world.properties.clinic.looted or float(world.player.hp) <= 0 or world.player.pos.distance_to(site(world)) >= 85 or not reason(world, false).is_empty():
		return false
	if not WorkOrders.approve(world, "restore:clinic", "clinic", WorkRecipes.recipe(world.catalog, "clinic"), site(world)):
		world.note("Need materials or space on the work board.")
		return false
	world.clinic.started = true
	return true


static func executor(world: RefCounted) -> String:
	if world.player_at_worksite("clinic") and float(world.player.hp) > 0:
		return "you"
	var chosen: String = ""
	for a: Dictionary in world.survivors:
		if a.order == "Clinic" and float(a.hp) > 0 and a.pos.distance_to(site(world)) < 40 and a.duty.clear_left <= 0 and not a.activity.begins_with("Sheltering"):
			if chosen.is_empty() or str(a.id) < chosen:
				chosen = a.id
	return chosen


static func patient(world: RefCounted) -> Dictionary:
	var selected: Dictionary = {}
	var distance: float = INF
	for a: Dictionary in [world.player] + world.survivors:
		var next: float = a.pos.distance_to(site(world))
		if a.id == world.carry.patient or float(a.hp) >= full_health(world, a) or next >= 70:
			continue
		if next < distance or (is_equal_approx(next, distance) and str(a.id) < str(selected.get("id", ""))):
			selected = a
			distance = next
	return selected


static func treat(world: RefCounted) -> bool:
	if not world.clinic.done or float(world.player.hp) <= 0 or world.player.pos.distance_to(site(world)) >= 85 or not reason(world).is_empty():
		return false
	var a: Dictionary = patient(world)
	if a.is_empty() or world.clinic.patients.has(a.id):
		return false
	if world.medicine < int(world.balance.treatment_cost):
		world.note("Need medicine for treatment.")
		return false
	world.medicine -= int(world.balance.treatment_cost)
	world.clinic.patients[a.id] = {"progress": 0.0}
	return true


static func step(world: RefCounted, dt: float) -> void:
	if not world.clinic.started:
		return
	for id: String in world.clinic.patients.keys():
		var a: Dictionary = Equipment.person(world, id)
		if float(a.hp) >= full_health(world, a):
			world.clinic.patients.erase(id)
	var worker: String = executor(world)
	var blocked: String = reason(world, world.clinic.done)
	if worker.is_empty() and blocked.is_empty():
		blocked = "Need worker at clinic"
	if not world.clinic.done:
		if not blocked.is_empty():
			WorkOrders.block(world, "restore:clinic", blocked)
			return
		world.clinic.done = WorkOrders.advance(world, "restore:clinic", worker, dt)
		world.clinic.progress = float(WorkOrders.current(world, "restore:clinic").work_done)
		if world.clinic.done:
			world.note("Clinic ready. Bring patients here for treatment.")
			for a: Dictionary in world.survivors:
				if a.order == "Clinic":
					world.finish_job(a)
		return
	if not blocked.is_empty():
		return
	# Only one present patient receives one effective site rate, regardless of workers.
	var ids: Array = world.clinic.patients.keys()
	ids.sort()
	for id: String in ids:
		var a: Dictionary = Equipment.person(world, id)
		if float(a.hp) >= full_health(world, a):
			world.clinic.patients.erase(id)
			continue
		if a.id == world.carry.patient or a.pos.distance_to(site(world)) >= 70:
			continue
		var paid: Dictionary = world.clinic.patients[id]
		paid.progress = minf(float(world.balance.treatment_seconds), float(paid.progress) + dt)
		if paid.progress >= float(world.balance.treatment_seconds):
			a.hp = full_health(world, a)
			world.clinic.patients.erase(id)
			world.note(a.name + " recovered at the clinic.")
		return


static func cancel(world: RefCounted, socket: String) -> bool:
	if socket != "restore:clinic" or not WorkOrders.cancel(world, socket):
		return false
	world.clinic = initial()
	for a: Dictionary in world.survivors:
		if a.order == "Clinic":
			world.finish_job(a, true)
	return true


static func context(world: RefCounted) -> String:
	if not world.clinic.started:
		return WorkOrders.cost_prompt(world, "Clinic", ["clinic"], int(world.balance.clinic_cost))
	if not world.clinic.done:
		return "R Restore · %d%%" % int(100 * float(world.clinic.progress) / float(world.balance.clinic_seconds))
	var a: Dictionary = patient(world)
	if a.is_empty():
		return ""
	if world.clinic.patients.has(a.id):
		return "R Treat %s · %d%%" % [a.name, int(100 * float(world.clinic.patients[a.id].progress) / float(world.balance.treatment_seconds))]
	return "E Treat %s · %d medicine" % [a.name, int(world.balance.treatment_cost)]


static func full_health(world: RefCounted, a: Dictionary) -> float:
	return float(world.balance.player_health if a.id == "you" else world.balance.survivor_health)
