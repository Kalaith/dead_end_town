extends RefCounted
## Authored one-time supply caches in the open (the market plaza, a car park, the freight road): search one with E
## when no zombie is close. What was taken is remembered by id, so a cache never refills.
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const REACH: float = 60.0
const SAFE_RADIUS: float = 170.0


static func nearby(world: RefCounted) -> Dictionary:
	if float(world.player.hp) <= 0:
		return {}
	for c: Dictionary in world.catalog.get("caches", []):
		if not world.caches_taken.has(c.id) and world.player.pos.distance_to(Routes.point(c.pos)) <= REACH:
			return c
	return {}


static func context(world: RefCounted) -> String:
	var c: Dictionary = nearby(world)
	if c.is_empty():
		return ""
	if Combat.danger(world, Routes.point(c.pos), SAFE_RADIUS):
		return "Clear the zombies before searching the %s" % str(c.name).to_lower()
	return "E Search the %s" % str(c.name).to_lower()


static func press(world: RefCounted) -> bool:
	var c: Dictionary = nearby(world)
	if c.is_empty():
		return false
	if Combat.danger(world, Routes.point(c.pos), SAFE_RADIUS):
		world.note("Clear the zombies before searching the %s." % str(c.name).to_lower())
		return true
	world.caches_taken.append(c.id)
	world.materials += int(c.materials)
	world.food += int(c.food)
	world.medicine += int(c.medicine)
	world.note(str(c.line))
	return true
