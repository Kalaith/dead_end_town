extends RefCounted
## The garage's first equipment chain: committed work and one physical loadout.
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Routes = preload("res://scripts/sim/routes.gd")


static func initial() -> Dictionary:
	return {"started": false, "progress": 0.0, "done": false, "armour_started": false, "armour_progress": 0.0, "armour_done": false, "equipped": false}


static func safe(world: RefCounted) -> bool:
	return world.properties.garage.claimed and not Combat.danger(world, Routes.point(world.definition("garage").site), 230)


static func context(world: RefCounted) -> String:
	var state: Dictionary = world.workshop
	if not safe(world):
		return "Clear nearby threats"
	if not state.started:
		return WorkOrders.cost_prompt(world, "Workshop", ["garage"], int(world.balance.workshop_cost))
	if not state.done:
		return "R Restore   F Assign"
	if not state.armour_started:
		return WorkOrders.cost_prompt(world, "Restore gear", ["garage"], int(world.balance.armour_cost))
	if not state.armour_done and not world.safe_connected("garage"):
		return "Secure home route"
	if not state.armour_done:
		return "R Restore   F Assign"
	if not state.equipped and world.equipment.iron.is_empty() and world.equipment.shield.is_empty() and world.properties.library.looted:
		return "E Equip Paige   F Loadouts"
	return "F Loadouts"


static func interact(world: RefCounted) -> void:
	if not safe(world):
		world.note("Clear the workshop area before working or changing equipment.")
		return
	var state: Dictionary = world.workshop
	if not state.started:
		if Restoration.approve(world, "workshop"):
			state.started = true
			world.note("Workshop materials committed. Hold R here or assign a survivor with F.")
	elif state.done and not state.armour_started:
		if Restoration.approve(world, "armour"):
			state.armour_started = true
			world.note("Cached sword, iron armour and shield on the bench. Hold R or assign a survivor with F.")
	elif state.armour_done and not state.equipped and world.equipment.iron.is_empty() and world.equipment.shield.is_empty():
		var site: Vector2 = Routes.point(world.definition("garage").site)
		for a: Dictionary in world.survivors:
			if a.id == "paige" and float(a.hp) > 0 and a.pos.distance_to(site) < 85:
				if not Equipment.equip(world, a.id, "protection", "iron"):
					return
				Equipment.equip(world, a.id, "shield", "shield")
				world.note("Paige: 'Now I can hold the door.' Iron armour and shield equipped.")
				return
		world.note("Bring Paige to the workshop to fit the armour." if world.properties.library.claimed else "Armour and shield stored at the bench.")


static func unfinished(world: RefCounted) -> bool:
	return (world.workshop.started and not world.workshop.done) or (world.workshop.armour_started and not world.workshop.armour_done)


static func step(world: RefCounted, dt: float) -> void:
	if not unfinished(world):
		return
	var armour: bool = world.workshop.done
	if Restoration.step(world, "armour" if armour else "workshop", dt):
		world.note("Recovered gear ready." if armour else "Workshop ready. E restores the recovered gear.")
		for a: Dictionary in world.survivors:
			if a.order in ["Build", "Workshop"] and a.job == "garage":
				world.finish_job(a)
