extends RefCounted
## The garage's first equipment chain: committed work and one physical loadout.
const Combat = preload("res://scripts/sim/combat.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func initial() -> Dictionary:
	return {"started": false, "progress": 0.0, "done": false, "armour_started": false, "armour_progress": 0.0, "armour_done": false, "equipped": false}


static func safe(world: RefCounted) -> bool:
	return world.properties.garage.claimed and world.connected("garage") and not Combat.danger(world, Routes.point(world.definition("garage").site), 230)


static func context(world: RefCounted) -> String:
	var state: Dictionary = world.workshop
	if not safe(world):
		return "Workshop unsafe / clear nearby shamblers before work or equipping"
	if not state.started:
		return "E / Restore workshop (%d materials)" % int(world.balance.workshop_cost)
	if not state.done:
		return "R / Restore workshop %d%%   |   F / Team orders" % int(float(state.progress) / float(world.balance.workshop_seconds) * 100)
	if not state.armour_started:
		return "E / Restore cached armour and shield (%d materials)" % int(world.balance.armour_cost)
	if not state.armour_done:
		return "R / Restore armour %d%%   |   F / Team orders" % int(float(state.armour_progress) / float(world.balance.armour_seconds) * 100)
	if not state.equipped:
		return "E / Fit Paige's armour and shield / bring her to this bench"
	return "Paige equipped / iron armour and shield / slower, stronger at the gate"


static func interact(world: RefCounted) -> void:
	if not safe(world):
		world.note("Clear the workshop area before working or changing equipment.")
		return
	var state: Dictionary = world.workshop
	if not state.started:
		if _reserve(world, "workshop_cost"):
			state.started = true
			world.note("Workshop materials committed. Hold R here or assign a survivor with F.")
	elif state.done and not state.armour_started:
		if _reserve(world, "armour_cost"):
			state.armour_started = true
			world.note("Cached iron armour and shield on the bench. Hold R or assign a survivor with F.")
	elif state.armour_done and not state.equipped:
		var site: Vector2 = Routes.point(world.definition("garage").site)
		for a: Dictionary in world.survivors:
			if a.id == "paige" and float(a.hp) > 0 and a.pos.distance_to(site) < 85:
				state.equipped = true
				world.note("Paige: 'Now I can hold the door.' Iron armour and shield equipped.")
				return
		world.note("Bring Paige to the workshop alive to fit the armour. Use 1 to have her follow.")


static func _reserve(world: RefCounted, cost_key: String) -> bool:
	var cost: int = int(world.balance[cost_key])
	if world.materials < cost:
		world.note("Need %d materials; stockpile has %d." % [cost, world.materials])
		return false
	world.materials -= cost
	return true


static func unfinished(world: RefCounted) -> bool:
	return (world.workshop.started and not world.workshop.done) or (world.workshop.armour_started and not world.workshop.armour_done)


static func step(world: RefCounted, dt: float) -> void:
	if not unfinished(world) or not safe(world):
		return
	var site: Vector2 = Routes.point(world.definition("garage").site)
	var executor: bool = world.working and world.player.pos.distance_to(site) < 85
	for a: Dictionary in world.survivors:
		if a.order in ["Build", "Workshop"] and a.job == "garage" and float(a.hp) > 0 and a.pos.distance_to(site) < 40:
			executor = true
	if not executor:
		return
	var armour: bool = world.workshop.done
	var key: String = "armour_progress" if armour else "progress"
	var duration: float = float(world.balance.armour_seconds if armour else world.balance.workshop_seconds)
	world.workshop[key] = minf(duration, float(world.workshop[key]) + dt)
	if float(world.workshop[key]) >= duration:
		world.workshop["armour_done" if armour else "done"] = true
		world.note("Iron armour and shield ready. Bring Paige to the bench and press E." if armour else "Workshop restored. E at the bench starts restoring the cached armour and shield.")
		for a: Dictionary in world.survivors:
			if a.order == "Build" and a.job == "garage":
				a.order = "Home"
				a.job = ""

