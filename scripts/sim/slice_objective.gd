extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")


static func initial() -> Dictionary:
	return {"phase": "preparing", "held": 0.0, "blocked": "", "downs": 0}


static func readiness(world: RefCounted) -> String:
	for p: Dictionary in world.catalog.properties:
		if p.id in ["residence", "munitions"]:
			continue
		if not world.properties[p.id].claimed:
			return "Reclaim all four properties. Search cleared porches with E."
		if world.remaining(p.id) > 0:
			return "Clear the occupied yards before the neighbourhood watch."
	for p: Dictionary in world.catalog.properties:
		if p.id in ["residence", "munitions"]:
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


static func start(world: RefCounted) -> bool:
	if world.slice_state.phase != "preparing":
		return false
	var reason: String = readiness(world)
	if not reason.is_empty():
		world.note(reason)
		return false
	if world.player.pos.distance_to(Routes.point(world.definition("home").site)) > float(world.catalog.slice.start_range):
		world.note("Return to the home porch to begin the neighbourhood watch.")
		return false
	world.slice_state.downs = world.downs
	world.slice_state.phase = "watch"
	world.note("Neighbourhood watch begins. Hold the connected, supplied street for %d active seconds." % int(world.catalog.slice.hold_seconds))
	return true


static func step(world: RefCounted, dt: float) -> void:
	if world.slice_state.phase != "watch":
		return
	var reason: String = readiness(world)
	if world.downs > int(world.slice_state.downs):
		world.slice_state.downs = world.downs
		reason = "The player fell. Recover and regroup."
	if not reason.is_empty():
		world.slice_state.held = 0.0
		if world.slice_state.blocked != reason:
			world.note("Watch interrupted. " + reason + " The watch restarts when ready.")
		world.slice_state.blocked = reason
		return
	if not world.slice_state.blocked.is_empty():
		world.note("The neighbourhood is ready again. The watch restarts.")
	world.slice_state.blocked = ""
	world.slice_state.held = minf(float(world.catalog.slice.hold_seconds), float(world.slice_state.held) + dt)
	if float(world.slice_state.held) >= float(world.catalog.slice.hold_seconds):
		world.slice_state.phase = "complete"
		world.note("A street worth keeping. The neighbourhood is connected, equipped and feeding itself. Slice complete.")


static func next(world: RefCounted) -> String:
	if world.slice_state.phase == "complete":
		return "Slice complete. Continue tending the street, or start a new street."
	if world.slice_state.phase == "watch":
		if not world.slice_state.blocked.is_empty():
			return "WATCH PAUSED / " + world.slice_state.blocked
		return "NEIGHBOURHOOD WATCH / %ds remaining. Keep all yards connected, clear and supplied." % ceili(float(world.catalog.slice.hold_seconds) - float(world.slice_state.held))
	for p: Dictionary in world.catalog.properties:
		if world.properties[p.id].looted and not world.properties[p.id].claimed:
			return "Clear and reclaim " + p.name + " at its porch with E."
	if not world.properties.garden.looted or not world.properties.library.looted or not world.properties.garage.looted:
		return "Search nearby cleared properties. Build useful facilities and join the yards as you discover them."
	var reason: String = readiness(world)
	return reason if not reason.is_empty() else "Return to the home porch, then begin the neighbourhood watch in pause."
