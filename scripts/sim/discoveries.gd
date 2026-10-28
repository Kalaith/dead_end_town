extends RefCounted
## New properties separate local search rewards from their connected first claim.
const Roster = preload("res://scripts/sim/roster.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")


static func search(world: RefCounted, id: String) -> bool:
	var p: Dictionary = world.definition(id)
	if p.is_empty() or not p.available or not p.has("search") or world.properties[id].looted:
		return false
	var site: Vector2 = Routes.point(p.site)
	if float(world.player.hp) <= 0 or world.player.pos.distance_to(site) >= 85:
		return false
	if world.remaining(id) > 0 or Combat.danger(world, site, 170):
		world.note("Clear the site before searching.")
		return false
	world.properties[id].looted = true
	world.materials += int(p.search.materials)
	world.food += int(p.food_cache)
	world.medicine += int(p.search.medicine)
	if not str(p.search.survivor).is_empty():
		Roster.recruit(world, p.search.survivor)
	world.note(p.search.line)
	return true
