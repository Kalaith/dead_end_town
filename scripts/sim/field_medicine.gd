extends RefCounted
const Equipment = preload("res://scripts/sim/equipment.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const RecoverySalvage = preload("res://scripts/sim/recovery_salvage.gd")


static func eligible(world: RefCounted, a: Dictionary) -> bool:
	return not a.is_empty() and float(a.hp) > 0 and float(a.hp) < float(world.balance.player_health if a.id == "you" else world.balance.survivor_health) and not Carrying.carried(world, a.id)


static func local(world: RefCounted, user: Dictionary, patient: Dictionary) -> bool:
	return eligible(world, patient) and float(user.hp) > 0 and not Carrying.burdened(world, user.id) and user.pos.distance_to(patient.pos) <= float(world.balance.field_range) and world.routes.line_clear(user.pos, patient.pos)


static func clear(world: RefCounted, user: Dictionary, patient: Dictionary) -> bool:
	return not Combat.danger(world, user.pos, 170) and not Combat.danger(world, patient.pos, 170)


static func player_target(world: RefCounted) -> Dictionary:
	if world.equipment.field_bag != "you" or Carrying.occupied(world) or not Carrying.nearby(world).is_empty() or not Neighbourhood.nearby(world).is_empty() or not Roadworks.nearby(world).is_empty() or not RecoverySalvage.nearby(world).is_empty():
		return {}
	for p: Dictionary in world.catalog.properties:
		if world.player.pos.distance_to(Routes.point(p.gate)) < 76 or world.player.pos.distance_to(Routes.point(p.site)) < 85:
			return {}
	var chosen: Dictionary = {}
	var distance: float = INF
	for a: Dictionary in world.survivors:
		if not local(world, world.player, a):
			continue
		var next: float = world.player.pos.distance_squared_to(a.pos)
		if next < distance or (is_equal_approx(next, distance) and str(a.id) < str(chosen.get("id", ""))):
			chosen = a
			distance = next
	return chosen if not chosen.is_empty() else world.player if eligible(world, world.player) else {}


static func reason(world: RefCounted, user: Dictionary, patient_id: String) -> String:
	if user.is_empty() or world.equipment.field_bag != user.id:
		return "Equip the field bag first"
	var patient: Dictionary = Equipment.person(world, patient_id)
	if not local(world, user, patient):
		return "Bring a standing injured patient nearby"
	if not clear(world, user, patient):
		return "Clear nearby threats"
	if not world.field_care.has(patient_id) and world.medicine < int(world.balance.field_medicine_cost):
		return "Need medicine"
	return ""


static func step(world: RefCounted, dt: float) -> void:
	for id: String in world.field_care.keys():
		var a: Dictionary = Equipment.person(world, id)
		if not a.is_empty() and float(a.hp) >= float(world.balance.player_health if id == "you" else world.balance.survivor_health):
			world.field_care.erase(id)
	var owner: String = world.equipment.field_bag
	if owner.is_empty():
		return
	var user: Dictionary = Equipment.person(world, owner)
	var patient: Dictionary = player_target(world) if owner == "you" and world.working else Equipment.person(world, user.job) if user.order == "Field" else {}
	if patient.is_empty():
		return
	if not eligible(world, patient):
		if user.order == "Field":
			world.finish_job(user)
		return
	if not local(world, user, patient) or not clear(world, user, patient):
		if user.order == "Field":
			user.activity = "Bring patient nearby" if not local(world, user, patient) else "Clear nearby threats"
		return
	if not world.field_care.has(patient.id):
		if world.medicine < int(world.balance.field_medicine_cost):
			return
		world.medicine -= int(world.balance.field_medicine_cost)
		world.field_care[patient.id] = 0.0
	world.field_care[patient.id] = minf(float(world.balance.field_seconds), float(world.field_care[patient.id]) + dt)
	if user.order == "Field":
		user.activity = "Field treatment"
	if float(world.field_care[patient.id]) >= float(world.balance.field_seconds):
		patient.hp = minf(float(world.balance.player_health if patient.id == "you" else world.balance.survivor_health), float(patient.hp) + float(world.balance.field_heal))
		world.field_care.erase(patient.id)
		if user.order == "Field":
			world.finish_job(user)


static func context(world: RefCounted) -> String:
	var patient: Dictionary = player_target(world)
	if patient.is_empty():
		return ""
	if not clear(world, world.player, patient):
		return "Clear nearby threats"
	if world.field_care.has(patient.id):
		return "R Treat %s · %d%%" % [patient.name, int(100 * float(world.field_care[patient.id]) / float(world.balance.field_seconds))]
	return "Need medicine" if world.medicine < int(world.balance.field_medicine_cost) else "R Treat %s · %d medicine" % [patient.name, int(world.balance.field_medicine_cost)]
