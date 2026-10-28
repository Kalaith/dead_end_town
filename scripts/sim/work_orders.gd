extends RefCounted
const Acoustics = preload("res://scripts/sim/noise.gd")
## One prepaid bundle and one executor per socket. Terminal records prevent replayed refunds.


static func initial() -> Dictionary:
	return {"sequence": 0, "sites": {}}


static func current(world: RefCounted, socket: String) -> Dictionary:
	return world.orders.sites.get(socket, {})


static func pending(order: Dictionary) -> bool:
	return not order.is_empty() and order.phase in ["approved", "working", "blocked"]


static func record(sequence: int, socket: String, target: String, recipe: Dictionary, stand: Vector2) -> Dictionary:
	return {"id": "work_%d" % sequence, "sequence": sequence, "socket": socket, "target": target, "recipe": recipe.id, "kind": recipe.kind, "phase": "approved", "inputs": recipe.inputs.duplicate(true), "outputs": recipe.outputs.duplicate(true), "work_required": float(recipe.seconds), "work_done": 0.0, "executor": "", "stand": [stand.x, stand.y], "priority": false, "blocked_reason": "", "output_granted": false, "salvage_paid": false}


static func approve(world: RefCounted, socket: String, target: String, recipe: Dictionary, stand: Vector2) -> bool:
	if recipe.kind != "production":
		var count: int = 0
		for order: Dictionary in world.orders.sites.values():
			if order.kind != "production" and pending(order):
				count += 1
		if count >= int(world.catalog.work.pending_limit):
			return false
	if pending(current(world, socket)):
		return false
	for stock: String in recipe.inputs:
		if amount(world, stock) < int(recipe.inputs[stock]):
			return false
	# Validate every input before moving the entire bundle.
	for stock: String in recipe.inputs:
		add(world, stock, -int(recipe.inputs[stock]))
	world.orders.sequence = int(world.orders.sequence) + 1
	world.orders.sites[socket] = record(int(world.orders.sequence), socket, target, recipe, stand)
	return true


static func amount(world: RefCounted, stock: String) -> int:
	return int(world.firearms.bullets) if stock == "bullets" else int(world.get(stock))


static func add(world: RefCounted, stock: String, count: int) -> void:
	if stock == "bullets":
		world.firearms.bullets = int(world.firearms.bullets) + count
	else:
		world.set(stock, int(world.get(stock)) + count)


static func block(world: RefCounted, socket: String, reason: String) -> void:
	var order: Dictionary = current(world, socket)
	if pending(order):
		order.phase = "blocked"
		order.blocked_reason = reason
		order.executor = ""


static func advance(world: RefCounted, socket: String, executor: String, dt: float, completion_allowed: bool = true) -> bool:
	var order: Dictionary = current(world, socket)
	if not pending(order) or executor.is_empty() or dt <= 0:
		return false
	order.executor = executor
	order.blocked_reason = ""
	order.phase = "working"
	if order.kind in ["construction", "repair"]:
		Acoustics.emit(world, str(order.target), "work", Vector2(float(order.stand[0]), float(order.stand[1])))
	order.work_done = minf(float(order.work_required), float(order.work_done) + dt)
	if float(order.work_done) < float(order.work_required):
		return false
	if not completion_allowed:
		block(world, socket, "Clear work area")
		return false
	# Output and terminal flag change in the same simulation command, before a save can run.
	for stock: String in order.outputs:
		add(world, stock, int(order.outputs[stock]))
	order.output_granted = true
	order.phase = "completed"
	order.executor = ""
	return true


static func refund(order: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if not pending(order):
		return result
	var fraction: float = float(order.work_done) / float(order.work_required)
	var loss: float = 1.0 if order.kind in ["production", "repair"] else 0.25
	for stock: String in order.inputs:
		result[stock] = floori(float(order.inputs[stock]) * (1.0 - loss * fraction))
	return result


static func cancel(world: RefCounted, socket: String, destroyed: bool = false) -> bool:
	var order: Dictionary = current(world, socket)
	if not pending(order):
		if destroyed and not order.is_empty() and order.phase in ["completed", "cancelled"] and order.kind != "production":
			order.phase = "destroyed"
			order.output_granted = false
			order.salvage_paid = false
			return true
		return false
	if not destroyed:
		for stock: String in refund(order):
			add(world, stock, int(refund(order)[stock]))
	order.salvage_paid = not destroyed
	order.phase = "destroyed" if destroyed else "cancelled"
	order.executor = ""
	order.blocked_reason = ""
	return true


static func prioritise(world: RefCounted, socket: String, value: bool) -> bool:
	var order: Dictionary = current(world, socket)
	if not pending(order) or order.kind == "production":
		return false
	if value:
		for other: Dictionary in world.orders.sites.values():
			if other.target == order.target:
				other.priority = false
	order.priority = value
	return true


static func cost_prompt(world: RefCounted, label: String, requires: Array, cost: int) -> String:
	var field: bool = false
	for id: String in requires:
		field = field or not world.safe_connected(id)
	var text: String = "%s · E Commit field supplies · %d materials" % [label, cost] if field else "E %s · %d materials" % [label, cost]
	if world.materials - cost < int(world.production.material_reserve):
		text += " · uses reserve"
	return text
