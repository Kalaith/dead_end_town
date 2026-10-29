extends RefCounted
const Boss = preload("res://scripts/sim/boss.gd")
const Facility = preload("res://scripts/sim/facility.gd")


static func initial() -> Dictionary:
	return {"phase": "preparing", "held": 0.0, "blocked": "", "downs": 0}


static func readiness(world: RefCounted) -> String:
	for p: Dictionary in world.catalog.properties:
		if p.id not in ["home", "garden", "library", "garage"]:
			continue
		if not world.properties[p.id].claimed:
			return "Reclaim all four properties. Search cleared porches with E."
		if world.remaining(p.id) > 0:
			return "Clear the occupied yards before the neighbourhood watch."
	for p: Dictionary in world.catalog.properties:
		if p.id not in ["home", "garden", "library", "garage"]:
			continue
		if not world.safe_connected(p.id):
			return "Connect every yard to home through fenced passages and defended crossings."
	if not world.garden_done:
		return "Finish the garden beds with R or an assigned worker."
	if int(world.provisions.harvested) < int(world.catalog.slice.harvest_food):
		return "Tend the connected garden and deliver %d food (%d delivered)." % [int(world.catalog.slice.harvest_food), int(world.provisions.harvested)]
	if not world.workshop.armour_done:
		return "Restore the workshop and its recovered equipment cache."
	if world.equipment.iron.is_empty() or world.equipment.shield.is_empty() or (world.equipment.sword.is_empty() and world.equipment.crowbar.is_empty()):
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
		return "The baboon is down. Take the %s exit at the south-west corner when ready." % str(world.catalog.exit.name).to_lower()
	for p: Dictionary in world.catalog.properties:
		if world.properties[p.id].looted and not world.properties[p.id].claimed:
			return "Clear and reclaim " + p.name + " at its porch with E."
	if not Facility.state(world, "garden").looted or not Facility.state(world, "library").looted or not Facility.state(world, "garage").looted:
		return "Search nearby cleared properties. Build useful facilities and join the yards as you discover them."
	var reason: String = readiness(world)
	return reason if not reason.is_empty() else "Prepared. When you choose, face the baboon at the bridge, the south-west corner. See READINESS in pause."
