extends RefCounted
## Shared garden/bench construction, with legacy state fields as validated projections.
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func target(id: String) -> String:
	return "garden" if id == "garden" else "garage"


static func approve(world: RefCounted, id: String) -> bool:
	if id not in ["garden", "workshop", "armour"]:
		return false
	if (id == "garden" and world.garden_started) or (id == "workshop" and world.workshop.started) or (id == "armour" and (not world.workshop.done or world.workshop.armour_started)):
		return false
	var site_id: String = target(id)
	var site: Vector2 = Routes.point(world.definition(site_id).site)
	if float(world.player.hp) <= 0 or world.player.pos.distance_to(site) >= 85 or not world.properties[site_id].claimed or world.remaining(site_id) > 0 or Combat.danger(world, site, 170):
		world.note("Clear the site first.")
		return false
	if not WorkOrders.approve(world, "restore:" + id, site_id, WorkRecipes.recipe(world.catalog, id), site):
		world.note("Need materials or space on the work board.")
		return false
	if id == "garden":
		world.garden_started = true
	else:
		world.workshop["armour_started" if id == "armour" else "started"] = true
	return true


static func executor(world: RefCounted, site_id: String) -> String:
	if world.player_at_worksite(site_id) and float(world.player.hp) > 0:
		return "you"
	var chosen: String = ""
	var site: Vector2 = Routes.point(world.definition(site_id).site)
	for a: Dictionary in world.survivors:
		if a.order in ["Build", "Garden", "Workshop"] and a.job == site_id and float(a.hp) > 0 and a.pos.distance_to(site) < 40 and not a.activity.begins_with("Sheltering"):
			if chosen.is_empty() or str(a.id) < chosen:
				chosen = a.id
	return chosen


static func step(world: RefCounted, id: String, dt: float) -> bool:
	var socket: String = "restore:" + id
	var order: Dictionary = WorkOrders.current(world, socket)
	if not WorkOrders.pending(order):
		return false
	var site_id: String = target(id)
	var reason: String = ""
	if not world.properties[site_id].claimed:
		reason = "Reclaim site"
	elif world.remaining(site_id) > 0 or Combat.danger(world, Routes.point(world.definition(site_id).site), 230 if site_id == "garage" else 170):
		reason = "Clear nearby threats"
	elif id == "armour" and not world.safe_connected(site_id):
		reason = "Secure home route"
	var worker: String = executor(world, site_id)
	if reason.is_empty() and worker.is_empty():
		reason = "Need worker at site"
	if not reason.is_empty():
		WorkOrders.block(world, socket, reason)
		return false
	var completed: bool = WorkOrders.advance(world, socket, worker, dt)
	if id == "garden":
		world.garden_progress = float(order.work_done)
		world.garden_done = completed
	else:
		world.workshop["armour_progress" if id == "armour" else "progress"] = float(order.work_done)
		world.workshop["armour_done" if id == "armour" else "done"] = completed
	return completed


static func cancel(world: RefCounted, socket: String) -> bool:
	if not socket.begins_with("restore:"):
		return false
	var id: String = socket.trim_prefix("restore:")
	if id not in ["garden", "workshop", "armour"] or not WorkOrders.cancel(world, socket):
		return false
	if id == "garden":
		world.garden_started = false
		world.garden_progress = 0.0
	else:
		world.workshop["armour_started" if id == "armour" else "started"] = false
		world.workshop["armour_progress" if id == "armour" else "progress"] = 0.0
	for a: Dictionary in world.survivors:
		if a.job == target(id) and a.order in ["Build", "Garden", "Workshop"]:
			a.order = "Hold" if a.id == "ellis" else "Home"
			a.job = ""
	return true
