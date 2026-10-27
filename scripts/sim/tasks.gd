extends RefCounted
## Named survivor orders share physical work sites, never a global worker slot.
const Routes = preload("res://scripts/sim/routes.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")


static func person(world: RefCounted, id: String) -> Dictionary:
	for a: Dictionary in world.survivors:
		if a.id == id:
			return a
	return {}


static func options(world: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"id": "home", "label": "Guard home"},
		{"id": "garden", "label": "Garden: build and tend"},
		{"id": "garage", "label": "Workshop: build and restore"},
		{"id": "follow", "label": "Follow me"},
		{"id": "hold", "label": "Hold current position"},
		{"id": "engage", "label": "Engage nearby threats"},
	]
	for d: Dictionary in world.catalog.barricades:
		var s: Dictionary = world.roadworks[d.id]
		if s.phase == "empty":
			continue
		if s.phase != "ready" or float(s.hp) < float(world.balance.barricade_health):
			result.append({"id": "work:" + d.id, "label": "Work: " + d.name})
		if Roadworks.active(s):
			result.append({"id": "guard:" + d.id, "label": "Guard: " + d.name})
	for entry: Dictionary in result:
		entry.reason = unavailable(world, entry.id)
	return result


static func unavailable(world: RefCounted, task: String) -> String:
	match task:
		"home", "follow", "hold", "engage":
			return ""
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
	return "Unknown assignment"


static func assign(world: RefCounted, id: String, task: String) -> bool:
	var a: Dictionary = person(world, id)
	if a.is_empty():
		world.note("That survivor has not joined the team.")
		return false
	if float(a.hp) <= 0:
		world.note("Recover %s at home before assigning work." % a.name)
		return false
	var reason: String = unavailable(world, task)
	if not reason.is_empty():
		world.note(reason + ".")
		return false
	a.job = ""
	match task:
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
			for d: Dictionary in world.catalog.barricades:
				if task == "work:" + d.id:
					a.order = "Roadwork"
					a.job = d.id
					a.anchor = Routes.point(d.site)
				elif task == "guard:" + d.id:
					a.order = "Roadguard"
					a.anchor = Roadworks.guard_post(world, d)
	a.activity = "Heading to " + label(world, a)
	world.note("%s assigned: %s." % [a.name, label(world, a)])
	return true


static func selected(world: RefCounted, a: Dictionary) -> String:
	match a.order:
		"Garden":
			return "garden"
		"Workshop", "Build":
			return a.job
		"Roadwork":
			return "work:" + a.job
		"Roadguard":
			for d: Dictionary in world.catalog.barricades:
				if a.anchor.distance_to(Roadworks.guard_post(world, d)) < 10:
					return "guard:" + d.id
		"Follow", "Hold", "Engage":
			return a.order.to_lower()
	return "home"


static func label(world: RefCounted, a: Dictionary) -> String:
	var id: String = selected(world, a)
	for entry: Dictionary in options(world):
		if entry.id == id:
			return entry.label
	return "Guard home"
