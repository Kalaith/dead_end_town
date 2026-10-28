extends RefCounted
## Both food sites use one physical work rate and keep partial harvests while blocked.
const Greenhouse = preload("res://scripts/sim/greenhouse.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")


static func initial() -> Dictionary:
	return {"garden": false, "greenhouse": false}


static func target(world: RefCounted) -> int:
	return (world.survivors.size() + 1) * 2 + int(world.balance.food_target_buffer)


static func done(world: RefCounted, id: String) -> bool:
	return world.garden_done if id == "garden" else world.greenhouse.done


static func worker(world: RefCounted, id: String) -> String:
	return Restoration.executor(world, "garden") if id == "garden" else Greenhouse.executor(world)


static func reason(world: RefCounted, id: String) -> String:
	if not done(world, id):
		return "Restore beds first"
	if not world.properties[id].claimed:
		return "Reclaim site"
	if world.remaining(id) > 0 or Combat.danger(world, Routes.point(world.definition(id).site), 230):
		return "Clear nearby threats"
	if not world.safe_connected(id):
		return "Secure home route"
	if worker(world, id).is_empty():
		return "Need grower at site"
	if world.growing[id]:
		return "Food target reached"
	return ""


static func needed(world: RefCounted, id: String) -> bool:
	return done(world, id) and not world.growing[id] and world.food < target(world)


static func step(world: RefCounted, dt: float) -> void:
	for id: String in ["garden", "greenhouse"]:
		# One meal of hysteresis keeps routine growers at their posts between harvests.
		if world.food >= target(world):
			world.growing[id] = true
		elif world.food < target(world) - (world.survivors.size() + 1):
			world.growing[id] = false
		if not reason(world, id).is_empty():
			continue
		var seconds: float = float(world.balance.food_seconds if id == "garden" else world.balance.greenhouse_food_seconds)
		var progress: float = float(world.harvest if id == "garden" else world.greenhouse.harvest) + dt
		if progress >= seconds:
			progress -= seconds
			var count: int = int(world.balance.food_yield if id == "garden" else world.balance.greenhouse_yield)
			world.food += count
			world.provisions.harvested += count
			if world.food >= target(world):
				world.growing[id] = true
		if id == "garden":
			world.harvest = progress
		else:
			world.greenhouse.harvest = progress


static func summary(world: RefCounted) -> String:
	var text: String = "Food target: %d (two meals + recovery); resume below %d" % [target(world), target(world) - (world.survivors.size() + 1)]
	for id: String in ["garden", "greenhouse"]:
		if not world.properties[id].looted:
			continue
		var blocked: String = reason(world, id)
		var seconds: float = float(world.balance.food_seconds if id == "garden" else world.balance.greenhouse_food_seconds)
		var progress: float = float(world.harvest if id == "garden" else world.greenhouse.harvest)
		var count: int = int(world.balance.food_yield if id == "garden" else world.balance.greenhouse_yield)
		text += "\n%s: %d Food / %ds · %d%% · %s" % [id.capitalize(), count, int(seconds), int(100 * progress / seconds), "Growing" if blocked.is_empty() else blocked]
	return text
