extends RefCounted
## Named survivor orders share physical work sites, never a global worker slot.
const FieldMedicine = preload("res://scripts/sim/field_medicine.gd")
const CompanionRescue = preload("res://scripts/sim/companion_rescue.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")


static func person(world: RefCounted, id: String) -> Dictionary:
	for a: Dictionary in world.survivors:
		if a.id == id:
			return a
	return {}


static func options(world: RefCounted, a: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"id": "home", "label": "Guard home"},
		{"id": "follow", "label": "Follow me"},
		{"id": "hold", "label": "Hold current position"},
		{"id": "engage", "label": "Engage nearby threats"},
		{"id": "builder", "label": "Builder: approved projects"},
		{"id": "general", "label": "General worker"},
	]
	if world.properties.munitions.claimed:
		result.append({"id": "ammo", "label": "Craft bullets (%d materials / %d bullets)" % [int(world.catalog.firearm.material_cost), int(world.catalog.firearm.batch_bullets)]})
	if world.properties.clinic.claimed:
		result.append({"id": "clinic", "label": "Clinic"})
	if world.properties.garden.claimed:
		result.append({"id": "garden", "label": "Garden: build and tend"})
	if world.properties.garage.claimed:
		result.append({"id": "garage", "label": "Workshop: build and restore"})
	for p: Dictionary in world.catalog.properties:
		if world.properties[p.id].looted and float(world.properties[p.id].gate_hp) < float(world.balance.gate_health):
			result.append({"id": "repair:" + str(p.id), "label": "Repair: " + str(p.name)})
	for d: Dictionary in world.catalog.barricades:
		var s: Dictionary = world.roadworks[d.id]
		if s.phase == "empty":
			continue
		if s.phase != "ready" or float(s.hp) < float(world.balance.barricade_health):
			result.append({"id": "work:" + d.id, "label": "Work: " + d.name})
		if Roadworks.active(s):
			result.append({"id": "guard:" + d.id, "label": "Guard: " + d.name})
	for d: Dictionary in world.catalog.passages:
		if world.passages[d.id].started:
			result.append({"id": "passage:" + d.id, "label": "Build/repair: " + d.name})
	for patient: Dictionary in world.survivors:
		if float(patient.hp) <= 0:
			var owner: String = CompanionRescue.owner(world, patient.id)
			var shelter: String = str(world.rescue_jobs[owner].shelter) if world.rescue_jobs.has(owner) else CompanionRescue.destination(world, patient)
			result.append({"id": "rescue:" + str(patient.id), "label": "Rescue " + str(patient.name) + (" → " + shelter.capitalize() if not shelter.is_empty() else "")})
	if not a.is_empty() and world.equipment.field_bag == a.id:
		for patient: Dictionary in [world.player] + world.survivors:
			if FieldMedicine.eligible(world, patient):
				result.append({"id": "field:" + str(patient.id), "label": "Treat " + str(patient.name)})
	for entry: Dictionary in result:
		entry.reason = unavailable(world, entry.id, a)
	return result


static func unavailable(world: RefCounted, task: String, a: Dictionary = {}) -> String:
	if not a.is_empty() and Firearms.civilian(a) and (task in ["home", "engage"] or task.begins_with("guard:")):
		return "Ellis cannot fight or take a guard role"
	if task.begins_with("field:"):
		return FieldMedicine.reason(world, a, task.trim_prefix("field:"))
	if task.begins_with("rescue:"):
		return CompanionRescue.reason(world, task.trim_prefix("rescue:"), a)
	match task:
		"home", "follow", "hold", "engage", "builder", "general":
			return ""
		"clinic":
			return "Approve clinic restoration first" if not world.clinic.started else ""
		"ammo":
			return "Claim the ammunition workshop first" if not world.properties.munitions.claimed else ""
		"garden":
			return "Approve garden at its porch first" if not world.garden_started else ""
		"garage":
			return "Approve workshop restoration at its porch first" if not world.workshop.started else ""
	for d: Dictionary in world.catalog.barricades:
		if task == "work:" + d.id:
			var s: Dictionary = world.roadworks[d.id]
			return "Approve work here first" if s.phase == "empty" or (s.phase == "ready" and float(s.hp) >= float(world.balance.barricade_health)) else ""
		if task == "guard:" + d.id:
			return "Build this barricade first" if not Roadworks.active(world.roadworks[d.id]) else ""
	if task.begins_with("repair:"):
		var id: String = task.trim_prefix("repair:")
		return "Reclaim site" if not world.properties.has(id) or not world.properties[id].claimed else ""
	if task.begins_with("passage:"):
		var id: String = task.trim_prefix("passage:")
		return "Approve passage here first" if not world.passages.has(id) or not world.passages[id].started else ""
	return "Unknown assignment"


static func assign(world: RefCounted, id: String, task: String, announce: bool = true) -> bool:
	var a: Dictionary = person(world, id)
	if a.is_empty():
		if announce:
			world.note("That survivor has not joined the team.")
		return false
	if float(a.hp) <= 0:
		if announce:
			world.note("Recover %s at home before assigning work." % a.name)
		return false
	var reason: String = unavailable(world, task, a)
	if not reason.is_empty():
		if announce:
			world.note(reason + ".")
		return false
	if task.begins_with("rescue:"):
		if a.order == "Rescue" and a.job == task.trim_prefix("rescue:"):
			return true
		var blocked: String = CompanionRescue.assignment_reason(world, a, task.trim_prefix("rescue:"))
		if not blocked.is_empty():
			if announce:
				world.note(blocked + ".")
			return false
	CompanionRescue.release(world, a, false)
	Jobs.remember(world, a, task)
	a.job = ""
	match task:
		"builder", "general":
			a.order = "Idle"
			a.anchor = a.pos
		"clinic":
			a.order = "Clinic"
			a.job = "clinic"
			a.anchor = Routes.point(world.definition("clinic").site)
		"ammo":
			a.order = "Ammo"
			a.job = "munitions"
			a.anchor = Routes.point(world.definition("munitions").site)
		"home":
			a.order = "Home"
		"garden", "garage":
			a.order = "Garden" if task == "garden" else "Workshop"
			a.job = task
			a.anchor = Routes.point(world.definition(task).site)
		"follow", "hold", "engage":
			a.order = task.capitalize()
			a.anchor = a.pos if task == "hold" else world.player.pos
		_:
			if task.begins_with("field:"):
				a.order = "Field"
				a.job = task.trim_prefix("field:")
				a.anchor = a.pos
			if task.begins_with("rescue:"):
				CompanionRescue.start(world, a, task.trim_prefix("rescue:"))
			if task.begins_with("repair:"):
				a.order = "Repair"
				a.job = task.trim_prefix("repair:")
				a.anchor = Routes.point(world.definition(a.job).gate)
			if task.begins_with("passage:"):
				a.order = "Passage"
				a.job = task.trim_prefix("passage:")
				for d: Dictionary in world.catalog.passages:
					if d.id == a.job:
						var left: Vector2 = Routes.point(d.sites[0])
						var right: Vector2 = Routes.point(d.sites[1])
						a.anchor = left if a.pos.distance_to(left) <= a.pos.distance_to(right) else right
			for d: Dictionary in world.catalog.barricades:
				if task == "work:" + d.id:
					a.order = "Roadwork"
					a.job = d.id
					a.anchor = Routes.point(d.site)
				elif task == "guard:" + d.id:
					a.order = "Roadguard"
					a.anchor = Roadworks.guard_post(world, d)
	a.activity = "Heading to " + label(world, a)
	if not Jobs.temporary(task) and task not in ["follow", "hold", "engage"]:
		a.duty.anchor = [a.anchor.x, a.anchor.y]
	if announce:
		world.note("%s: %s" % [a.name, label(world, a)])
	return true


static func selected(world: RefCounted, a: Dictionary) -> String:
	return Jobs.current(world.catalog, a)


static func label(world: RefCounted, a: Dictionary) -> String:
	var id: String = selected(world, a)
	for entry: Dictionary in options(world, a):
		if entry.id == id:
			return entry.label
	return "Guard home"
