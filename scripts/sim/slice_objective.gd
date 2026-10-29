extends RefCounted
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Facility = preload("res://scripts/sim/facility.gd")


## The lots this area asks the player to hold, from the area's own `objective.reclaim` list.
static func core(world: RefCounted) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for p: Dictionary in world.catalog.properties:
		if p.id in world.catalog.objective.reclaim:
			found.append(p)
	return found


static func _wants(world: RefCounted, kind: String) -> bool:
	return core(world).any(func(p: Dictionary) -> bool: return p.facility == kind)


static func readiness(world: RefCounted) -> String:
	var lots: Array[Dictionary] = core(world)
	for p: Dictionary in lots:
		if not world.properties[p.id].claimed:
			return "Reclaim all %d properties. Search cleared porches with E." % lots.size()
		if world.remaining(p.id) > 0:
			return "Clear the occupied yards before the neighbourhood watch."
	for p: Dictionary in lots:
		if not world.safe_connected(p.id):
			return "Connect every yard to home through fenced passages and defended crossings."
	if _wants(world, "garden") and not world.garden_done:
		return "Finish the garden beds with R or an assigned worker."
	if _wants(world, "garden") and int(world.provisions.harvested) < int(world.catalog.slice.harvest_food):
		return "Tend the connected garden and deliver %d food (%d delivered)." % [int(world.catalog.slice.harvest_food), int(world.provisions.harvested)]
	if _wants(world, "garage") and not world.workshop.armour_done:
		return "Restore the workshop and its recovered equipment cache."
	if _wants(world, "garage") and (world.equipment.iron.is_empty() or world.equipment.shield.is_empty() or (world.equipment.sword.is_empty() and world.equipment.crowbar.is_empty())):
		return "Use F at the workshop to deploy a recovered weapon, iron armour and a shield."
	if float(world.player.hp) <= 0:
		return "Recover the player."
	for a: Dictionary in world.survivors:
		if float(a.hp) <= 0:
			return "Recover the downed team at home before the watch."
	if world.provisions.hungry or world.food < 1 + world.survivors.size():
		return "Keep enough food for one shared meal and resolve any shortage."
	return ""


static func next(world: RefCounted) -> String:
	if Boss.configured(world.catalog) and Boss.defeated(world):
		return "The %s is down. Take the %s when ready." % [ZombieTypes.type_name(world.catalog, str(world.catalog.boss.kind)).to_lower(), str(world.catalog.exit.name).to_lower()]
	for p: Dictionary in world.catalog.properties:
		if world.properties[p.id].looted and not world.properties[p.id].claimed:
			return "Clear and reclaim " + p.name + " at its porch with E."
	if core(world).any(func(p: Dictionary) -> bool: return not world.properties[p.id].looted):
		return "Search nearby cleared properties. Build useful facilities and join the yards as you discover them."
	var reason: String = readiness(world)
	if not reason.is_empty():
		return reason
	if not Boss.configured(world.catalog):
		return "Prepared. See READINESS in pause."
	return "Prepared. When you choose, face the %s. See READINESS in pause." % ZombieTypes.type_name(world.catalog, str(world.catalog.boss.kind)).to_lower()
