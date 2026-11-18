extends RefCounted
## The van's repair is a work-board project: holding R beside the stopped van approves it (its materials are paid
## once), and then the player or a survivor assigned from the board works it off. `vehicle.repair_paid` and
## `repair_progress` stay as projections of the order, so the saved van reads the same as before.
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const SOCKET: String = "van"
const RECIPE: String = "van_repair"
## The survivor order for this job; their job id is the socket.
const ORDER: String = "Van"


static func pos(world: RefCounted) -> Vector2:
	return Vector2(float(world.vehicle.x), float(world.vehicle.y))


static func damaged(world: RefCounted) -> bool:
	return bool(world.vehicle.present) and float(world.vehicle.hull) < float(world.catalog.vehicle.hull)


static func pending(world: RefCounted) -> bool:
	return WorkOrders.pending(WorkOrders.current(world, SOCKET))


## Where an assigned survivor stands to work: beside the van's flank.
static func stand(world: RefCounted) -> Vector2:
	return pos(world) + Vector2.from_angle(float(world.vehicle.heading) + PI / 2.0) * (float(world.catalog.vehicle.half_width) + 18.0)


static func step(world: RefCounted, dt: float) -> void:
	var state: Dictionary = world.vehicle
	if not bool(state.present):
		return
	var config: Dictionary = world.catalog.vehicle
	var player_here: bool = world.working and float(world.player.hp) > 0 and world.player.pos.distance_to(pos(world)) <= float(config.enter_range)
	if not pending(world):
		if not player_here or bool(state.driving) or not damaged(world):
			_sync(world)
			return
		if not WorkOrders.approve(world, SOCKET, SOCKET, WorkRecipes.recipe(world.catalog, RECIPE), stand(world)):
			return
	if bool(state.driving):
		WorkOrders.block(world, SOCKET, "Van in use")
		_sync(world)
		return
	var executor: String = "you" if player_here else _survivor(world)
	if executor.is_empty():
		WorkOrders.block(world, SOCKET, "Need worker at site")
		_sync(world)
		return
	if WorkOrders.advance(world, SOCKET, executor, dt):
		state.hull = minf(float(config.hull), float(state.hull) + float(config.repair_hull))
		world.note("Van repaired. Hull %d." % int(state.hull))
	_sync(world)


static func _survivor(world: RefCounted) -> String:
	var chosen: String = ""
	for a: Dictionary in world.survivors:
		if a.order == ORDER and float(a.hp) > 0 and a.pos.distance_to(stand(world)) < 40 and not a.activity.begins_with("Sheltering") and a.duty.clear_left <= 0:
			if chosen.is_empty() or str(a.id) < chosen:
				chosen = a.id
	return chosen


static func _sync(world: RefCounted) -> void:
	var order: Dictionary = WorkOrders.current(world, SOCKET)
	world.vehicle.repair_paid = WorkOrders.pending(order)
	world.vehicle.repair_progress = float(order.work_done) if WorkOrders.pending(order) else 0.0


## Cancelling from the work board refunds like any project and sends the worker back.
static func cancel(world: RefCounted, socket: String) -> bool:
	if socket != SOCKET or not WorkOrders.cancel(world, SOCKET):
		return false
	for a: Dictionary in world.survivors:
		if a.order == ORDER:
			world.finish_job(a, true)
	_sync(world)
	return true
