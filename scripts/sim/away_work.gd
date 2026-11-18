extends RefCounted
## Work an area finishes while the player is in another one, worked off on return from the time away. The garden
## and clinic yields live in AreaTravel; this is the committed work: a workshop or gear restoration already paid for
## carries on, and the ammunition bench keeps crafting under its own policy (mode, target and material reserve),
## paying for each batch from the stock left behind.
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Production = preload("res://scripts/sim/production.gd")
const Routes = preload("res://scripts/sim/routes.gd")
## Who the work board credits for work done while nobody was watching.
const EXECUTOR: String = "away"
## A guard against a policy that never stops: at most this many batches per return.
const MAX_BATCHES: int = 200


## Spends `away` seconds of work in `world` and notes what got done.
static func run(world: RefCounted, away: float) -> void:
	if away <= 0.0:
		return
	_restore(world, away)
	_ammunition(world, away)
	# Work left part-done waits for a real worker again.
	for order: Dictionary in world.orders.sites.values():
		if order.executor == EXECUTOR:
			order.executor = ""


## A restoration already started (and paid for) carries on: the workshop first, then the gear on its bench.
static func _restore(world: RefCounted, away: float) -> void:
	if not Facility.has(world.catalog, "garage") or not Facility.state(world, "garage").claimed:
		return
	var left: float = away
	for id: String in ["workshop", "armour"]:
		var socket: String = "restore:" + id
		var order: Dictionary = WorkOrders.current(world, socket)
		if not WorkOrders.pending(order) or left <= 0.0:
			continue
		var needed: float = float(order.work_required) - float(order.work_done)
		var done: bool = WorkOrders.advance(world, socket, EXECUTOR, minf(left, needed))
		left -= minf(left, needed)
		world.workshop["armour_progress" if id == "armour" else "progress"] = float(order.work_done)
		world.workshop["armour_done" if id == "armour" else "done"] = done
		if done:
			world.note("While you were away the workshop finished: " + ("the recovered gear is ready." if id == "armour" else "the workshop is ready."))
		elif id == "workshop":
			return


## The bench keeps the policy it was left with; each batch is paid for from this area's own stock.
static func _ammunition(world: RefCounted, away: float) -> void:
	if not Facility.has(world.catalog, "munitions") or not Facility.state(world, "munitions").looted or not Facility.state(world, "munitions").claimed:
		return
	var recipe: Dictionary = WorkRecipes.recipe(world.catalog, "bullets")
	var site: Vector2 = Routes.point(world.definition(Facility.resolve(world.catalog, "munitions")).site)
	var left: float = away
	var made: int = 0
	for i: int in range(MAX_BATCHES):
		var order: Dictionary = WorkOrders.current(world, "munitions")
		if not WorkOrders.pending(order):
			if not Production.start_reason(world).is_empty() or not WorkOrders.approve(world, "munitions", "munitions", recipe, site):
				break
			order = WorkOrders.current(world, "munitions")
		var needed: float = float(order.work_required) - float(order.work_done)
		if left < needed:
			WorkOrders.advance(world, "munitions", EXECUTOR, left)
			break
		left -= needed
		if WorkOrders.advance(world, "munitions", EXECUTOR, needed):
			made += int(order.outputs.get("bullets", 0))
			if world.production.mode == "once":
				world.production.mode = "stopped"
	if made > 0:
		world.note("While you were away the ammunition bench made %d bullets." % made)
