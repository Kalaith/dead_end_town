extends RefCounted
## Named survivor orders share physical work sites, never a global worker slot.
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
	]
	if world.properties.munitions.claimed:
		result.append({"id": "ammo", "label": "Craft bullets (%d materials / %d bullets)" % [int(world.catalog.firearm.material_cost), int(world.catalog.firearm.batch_bullets)]})
	if world.properties.garden.claimed:
		result.append({"id": "garden", "label": "Garden: build and tend"})
	if world.properties.garage.claimed:
		result.append({"id": "garage", "label": "Workshop: build and restore"})
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
	for entry: Dictionary in result:
		entry.reason = unavailable(world, entry.id, a)
	return result


static func unavailable(world: RefCounted, task: String, a: Dictionary = {}) -> String:
	if not a.is_empty() and Firearms.civilian(a) and (task in ["home", "engage"] or task.begins_with("guard:")):
		return "Ellis cannot fight or take a guard role"
	match task:
		"home", "follow", "hold", "engage":
			return ""
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
	if task.begins_with("passage:"):
		var id: String = task.trim_prefix("passage:")
		return "Approve passage here first" if not world.passages.has(id) or not world.passages[id].started else ""
	return "Unknown assignment"


static func assign(world: RefCounted, id: String, task: String) -> bool:
	var a: Dictionary = person(world, id)
	if a.is_empty():
		world.note("That survivor has not joined the team.")
		return false
	if float(a.hp) <= 0:
		world.note("Recover %s at home before assigning work." % a.name)
		return false
	var reason: String = unavailable(world, task, a)
	if not reason.is_empty():
		world.note(reason + ".")
		return false
	a.job = ""
	match task:
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
	world.note("%s: %s" % [a.name, label(world, a)])
	return true


static func selected(world: RefCounted, a: Dictionary) -> String:
	match a.order:
		"Ammo":
			return "ammo"
		"Garden":
			return "garden"
		"Workshop", "Build":
			return a.job
		"Passage":
			return "passage:" + a.job
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
