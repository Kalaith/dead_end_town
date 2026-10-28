extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")


static func initial() -> Dictionary:
	return {"started": false, "done": false, "progress": 0.0, "harvest": 0.0}


static func site(world: RefCounted) -> Vector2:
	return Routes.point(world.definition("greenhouse").site)


static func reason(world: RefCounted, productive: bool = true) -> String:
	if not world.properties.greenhouse.claimed:
		return "Reclaim greenhouse"
	if world.remaining("greenhouse") > 0 or Combat.danger(world, site(world), 230):
		return "Clear nearby threats"
	if productive and not world.safe_connected("greenhouse"):
		return "Secure home route"
	return ""


static func approve(world: RefCounted) -> bool:
	if world.greenhouse.started or not world.properties.greenhouse.looted or float(world.player.hp) <= 0 or world.player.pos.distance_to(site(world)) >= 85 or not reason(world, false).is_empty():
		return false
	if not WorkOrders.approve(world, "restore:greenhouse", "greenhouse", WorkRecipes.recipe(world.catalog, "greenhouse"), site(world)):
		world.note("Need materials or space on the work board.")
		return false
	world.greenhouse.started = true
	world.note("Greenhouse approved. Hold R or assign a grower with F.")
	return true


static func executor(world: RefCounted) -> String:
	if world.player_at_worksite("greenhouse") and float(world.player.hp) > 0:
		return "you"
	var chosen: String = ""
	for a: Dictionary in world.survivors:
		if a.order == "Greenhouse" and float(a.hp) > 0 and a.pos.distance_to(site(world)) < 40 and a.duty.clear_left <= 0 and not a.activity.begins_with("Sheltering"):
			if chosen.is_empty() or str(a.id) < chosen:
				chosen = a.id
	return chosen


static func step(world: RefCounted, dt: float) -> void:
	if not world.greenhouse.started or world.greenhouse.done:
		return
	var blocked: String = reason(world, false)
	var worker: String = executor(world)
	if blocked.is_empty() and worker.is_empty():
		blocked = "Need worker at greenhouse"
	if not blocked.is_empty():
		WorkOrders.block(world, "restore:greenhouse", blocked)
		return
	world.greenhouse.done = WorkOrders.advance(world, "restore:greenhouse", worker, dt)
	world.greenhouse.progress = float(WorkOrders.current(world, "restore:greenhouse").work_done)
	if world.greenhouse.done:
		world.note("Greenhouse restored. Tend here for %d Food per harvest." % int(world.balance.greenhouse_yield))
		for a: Dictionary in world.survivors:
			if a.order == "Greenhouse":
				world.finish_job(a)


static func cancel(world: RefCounted, socket: String) -> bool:
	if socket != "restore:greenhouse" or not WorkOrders.cancel(world, socket):
		return false
	world.greenhouse = initial()
	for a: Dictionary in world.survivors:
		if a.order == "Greenhouse":
			world.finish_job(a, true)
	return true


static func context(world: RefCounted) -> String:
	if not world.greenhouse.started:
		return WorkOrders.cost_prompt(world, "Greenhouse", ["greenhouse"], int(world.balance.greenhouse_cost))
	if not world.greenhouse.done:
		return "R Restore · %d%%" % int(100 * float(world.greenhouse.progress) / float(world.balance.greenhouse_seconds))
	var blocked: String = reason(world)
	if not blocked.is_empty():
		return blocked
	if world.growing.greenhouse:
		return "Food target reached · F Assign"
	return "R Tend · %d%% · %d Food   F Assign" % [int(100 * float(world.greenhouse.harvest) / float(world.balance.greenhouse_food_seconds)), int(world.balance.greenhouse_yield)]
