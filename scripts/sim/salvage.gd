extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")


static func initial() -> Dictionary:
	return {"garden": false, "library": false, "garage": false}


static func nearby(world: RefCounted) -> String:
	for id: String in world.timber:
		if world.properties[id].claimed and not world.timber[id] and world.player.pos.distance_to(Routes.point(world.definition(id).site)) < float(world.catalog.slice.start_range):
			return id
	return ""


static func collect(world: RefCounted) -> bool:
	var id: String = nearby(world)
	if id.is_empty() or world.remaining(id) > 0:
		world.note("Clear and secure a yard, then salvage its timber near the porch with Q.")
		return false
	world.timber[id] = true
	world.materials += int(world.balance.timber_materials)
	world.note("Recovered %d materials from the building's spare timber. This cache is now empty." % int(world.balance.timber_materials))
	return true
