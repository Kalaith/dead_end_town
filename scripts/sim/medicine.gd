extends RefCounted
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")


static func initial(catalog: Dictionary) -> Dictionary:
	return {"mode": "stopped", "target": int(catalog.balance.medicine_target), "reason": ""}


static func configure(world: RefCounted, mode: String, target: int, reserve: int) -> bool:
	if not world.clinic.done or mode not in ["stopped", "once", "repeat"] or target < 0 or target > 999 or reserve < 0 or reserve > 999:
		return false
	world.medicine_production.mode = mode
	world.medicine_production.target = target
	world.medicine_production.reason = ""
	world.production.material_reserve = reserve
	return true


static func pending(world: RefCounted) -> bool:
	return WorkOrders.pending(WorkOrders.current(world, "clinic_medicine"))


static func needed(world: RefCounted) -> bool:
	return pending(world) or world.medicine_production.mode == "once" or (world.medicine_production.mode == "repeat" and world.medicine < int(world.medicine_production.target))


static func start_reason(world: RefCounted) -> String:
	if world.medicine_production.mode == "stopped":
		return "Stopped"
	if world.medicine_production.mode == "repeat" and world.medicine >= int(world.medicine_production.target):
		return "Target met"
	var recipe: Dictionary = WorkRecipes.recipe(world.catalog, "medicine")
	if world.materials < int(recipe.inputs.materials):
		return "Need materials"
	if world.materials - int(recipe.inputs.materials) < int(world.production.material_reserve):
		return "Materials reserved"
	if world.food < int(recipe.inputs.food):
		return "Need food"
	if world.food - int(recipe.inputs.food) < Provisions.meal_cost(world):
		return "Food reserved for next meal"
	return ""


static func block(world: RefCounted, reason: String) -> void:
	world.medicine_production.reason = reason if needed(world) else ""
	WorkOrders.block(world, "clinic_medicine", reason)


static func step(world: RefCounted, executor: String, stand: Vector2, dt: float) -> void:
	if executor.is_empty():
		block(world, "Need worker at clinic")
		return
	if not pending(world):
		world.medicine_production.reason = start_reason(world)
		if not str(world.medicine_production.reason).is_empty():
			return
		if not WorkOrders.approve(world, "clinic_medicine", "clinic", WorkRecipes.recipe(world.catalog, "medicine"), stand):
			world.medicine_production.reason = "Need supplies"
			return
	world.medicine_production.reason = ""
	if WorkOrders.advance(world, "clinic_medicine", executor, dt) and world.medicine_production.mode == "once":
		world.medicine_production.mode = "stopped"


static func cancel(world: RefCounted) -> bool:
	if not WorkOrders.cancel(world, "clinic_medicine"):
		return false
	world.medicine_production.mode = "stopped"
	world.medicine_production.reason = "Stopped"
	return true
