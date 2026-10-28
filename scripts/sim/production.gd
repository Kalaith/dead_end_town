extends RefCounted
const WorkOrders = preload("res://scripts/sim/work_orders.gd")


static func initial(catalog: Dictionary) -> Dictionary:
	return {"mode": "stopped", "target": int(catalog.firearm.bullet_target), "material_reserve": int(catalog.firearm.material_reserve), "reason": ""}


static func configure(world: RefCounted, mode: String, target: int, reserve: int) -> bool:
	if not world.properties.munitions.looted or mode not in ["stopped", "once", "repeat"] or target < 0 or target > 999 or reserve < 0 or reserve > 999:
		return false
	world.production.mode = mode
	world.production.target = target
	world.production.material_reserve = reserve
	world.production.reason = ""
	return true


static func start_reason(world: RefCounted) -> String:
	var policy: Dictionary = world.production
	if policy.mode == "stopped":
		return "Stopped"
	if policy.mode == "repeat" and WorkOrders.amount(world, "bullets") + pending_output(world) >= int(policy.target):
		return "Target met"
	if world.materials < int(world.catalog.firearm.material_cost):
		return "Need materials"
	if world.materials - int(world.catalog.firearm.material_cost) < int(policy.material_reserve):
		return "Materials reserved"
	return ""


static func pending_output(world: RefCounted) -> int:
	var total: int = 0
	for order: Dictionary in world.orders.sites.values():
		if WorkOrders.pending(order):
			total += int(order.outputs.get("bullets", 0))
	return total


static func cancel(world: RefCounted) -> bool:
	if not WorkOrders.cancel(world, "munitions"):
		return false
	world.production.mode = "stopped"
	world.production.reason = "Stopped"
	return true
