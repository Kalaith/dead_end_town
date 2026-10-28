extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")


static func initial() -> Dictionary:
	return {"crowbar": "", "sword": "", "iron": "", "shield": ""}


static func person(world: RefCounted, id: String) -> Dictionary:
	if id == "you":
		return world.player
	for a: Dictionary in world.survivors:
		if a.id == id:
			return a
	return {}


static func unlocked(world: RefCounted, id: String) -> bool:
	if id == "bat" or id == "none":
		return true
	return world.properties.garage.looted if id == "crowbar" else world.workshop.armour_done


static func weapon(world: RefCounted, a: Dictionary) -> String:
	for id: String in ["crowbar", "sword"]:
		if world.equipment[id] == a.id:
			return id
	return "bat"


static func stats(world: RefCounted, a: Dictionary) -> Dictionary:
	return world.catalog.equipment.weapons[weapon(world, a)]


static func protected(world: RefCounted, a: Dictionary) -> bool:
	return world.equipment.iron == a.id


static func shielded(world: RefCounted, a: Dictionary) -> bool:
	return world.equipment.shield == a.id


static func speed(world: RefCounted, a: Dictionary) -> float:
	return float(world.balance.armour_speed_multiplier) if protected(world, a) else 1.0


static func description(world: RefCounted, a: Dictionary) -> String:
	var result: String = world.catalog.equipment.weapons[weapon(world, a)].name
	if protected(world, a):
		result += " + iron"
	if shielded(world, a):
		result += " + shield"
	return result


static func reason(world: RefCounted, id: String) -> String:
	var a: Dictionary = person(world, id)
	if a.is_empty() or float(a.hp) <= 0 or float(world.player.hp) <= 0:
		return "Recover this person before changing equipment."
	if not world.workshop.done or not world.safe_connected("garage"):
		return "Restore the workshop and secure its physical home route."
	var site: Vector2 = Routes.point(world.definition("garage").site)
	if world.player.pos.distance_to(site) > float(world.balance.equipment_range) or a.pos.distance_to(site) > float(world.balance.equipment_range):
		return "Bring the player and this person to the workshop bench."
	if world.remaining("garage") > 0:
		return "Clear the workshop yard before changing equipment."
	return ""


static func equip(world: RefCounted, actor_id: String, slot: String, item: String) -> bool:
	var blocked: String = reason(world, actor_id)
	if not blocked.is_empty():
		world.note(blocked)
		return false
	var valid: bool = (slot == "weapon" and item in ["bat", "crowbar", "sword"]) or (slot == "protection" and item in ["none", "iron"]) or (slot == "shield" and item in ["none", "shield"])
	if not valid or not unlocked(world, item):
		world.note("That equipment has not been recovered and restored.")
		return false
	if world.equipment.has(item) and not world.equipment[item].is_empty() and world.equipment[item] != actor_id:
		world.note("Return that unique item to the bench from its current wearer first.")
		return false
	for id: String in world.equipment:
		var same_slot: bool = (slot == "weapon" and id in ["crowbar", "sword"]) or (slot == "protection" and id == "iron") or (slot == "shield" and id == "shield")
		if same_slot and world.equipment[id] == actor_id:
			world.equipment[id] = ""
	if world.equipment.has(item):
		world.equipment[item] = actor_id
	# Retain the old display/save flag as a derived compatibility field.
	world.workshop.equipped = world.equipment.iron == "paige" and world.equipment.shield == "paige"
	world.note("%s: %s. Equipment changed at the bench." % [person(world, actor_id).name, description(world, person(world, actor_id))])
	return true
