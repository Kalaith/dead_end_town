extends RefCounted
## Authoritative fixed-step state. Presentation sends commands only.
const Jobs = preload("res://scripts/sim/jobs.gd")
const Repairs = preload("res://scripts/sim/repairs.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Production = preload("res://scripts/sim/production.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const Salvage = preload("res://scripts/sim/salvage.gd")
const SliceObjective = preload("res://scripts/sim/slice_objective.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Territory = preload("res://scripts/sim/territory.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const Tasks = preload("res://scripts/sim/tasks.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Workshop = preload("res://scripts/sim/workshop.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
var production: Dictionary
var orders: Dictionary = WorkOrders.initial()
var firearms: Dictionary = Firearms.initial()
var shot: Dictionary = {"from": Vector2.ZERO, "to": Vector2.ZERO, "left": 0.0}
var roam_rng := RandomNumberGenerator.new()
var catalog: Dictionary
var balance: Dictionary
var properties: Dictionary = {}
var player: Dictionary
var survivors: Array[Dictionary] = []
var zombies: Array[Dictionary] = []
var routes := Routes.new()
var materials: int
var food: int
var elapsed: float = 0.0
var approach: bool = false
var pressure: Dictionary
var garden_progress: float = 0.0
var garden_started: bool = false
var garden_done: bool = false
var harvest: float = 0.0
var gate_repair_target: String = "home"
var repair_reserved: bool = false
var messages: Array[String] = []
var move_input := Vector2.ZERO
var aim := Vector2.DOWN
var working: bool = false
var alert: String = "SAFE"
var downs: int = 0
var workshop: Dictionary = Workshop.initial()
var timber: Dictionary = Salvage.initial()
var slice_state: Dictionary = SliceObjective.initial()
var provisions: Dictionary = Provisions.initial()
var equipment: Dictionary = Equipment.initial()
var passages: Dictionary
var roadworks: Dictionary


func _init(data: Dictionary) -> void:
	catalog = data
	balance = data.balance
	production = Production.initial(data)
	roam_rng.seed = int(balance.roam_seed)
	passages = Neighbourhood.initial(data)
	roadworks = Roadworks.initial(data)
	pressure = Pressure.initial(data)
	materials = int(balance.starting_materials)
	food = int(balance.starting_food)
	player = actor("you", "You", Routes.point(balance.player_start), float(balance.player_health))
	survivors.append(actor("mara", "Mara", Routes.point(balance.mara_start), float(balance.survivor_health)))
	survivors[0].order = "Guard"
	survivors[0].anchor = survivors[0].pos
	Jobs.initialise(survivors[0], "home")
	for p: Dictionary in catalog.properties:
		properties[p.id] = {"claimed": p.id == "home", "looted": p.id == "home", "open": p.id != "home", "occupation": 0.0, "gate_hp": float(balance.gate_health) * (float(balance.home_gate_start_factor) if p.id == "home" else 1.0)}
		for spawn: Array in p.zombies:
			var z: Dictionary = actor("z%d" % zombies.size(), "Shambler", Routes.point(spawn), ZombieTypes.health(catalog))
			z.home = p.id
			z.raid = false
			zombies.append(z)
	Pressure.add_residents(self)
	rebuild_routes()
	note("Mara has the gate. Hold R to repair.")


static func actor(id: String, label: String, pos: Vector2, hp: float) -> Dictionary:
	return {"id": id, "name": label, "pos": pos, "hp": hp, "cooldown": 0.0, "flash": 0.0, "swing": 0.0, "facing": Vector2.DOWN, "order": "Follow", "job": "", "anchor": pos, "activity": "Ready", "roam_angle": 0.0, "roam_left": 0.0}


func rebuild_routes() -> void:
	var defences: Array[Rect2] = []
	for d: Dictionary in catalog.barricades:
		if Roadworks.active(roadworks[d.id]):
			defences.append(Routes.rectangle(d.rect))
	routes.rebuild(catalog.properties, properties, Routes.point(catalog.bounds), defences, Neighbourhood.openings(self), Neighbourhood.obstacles(self))


func definition(id: String) -> Dictionary:
	for p: Dictionary in catalog.properties:
		if p.id == id:
			return p
	return {}


func note(message: String) -> void:
	messages.append(message)
	if messages.size() > 5:
		messages.pop_front()


func step(dt: float) -> void:
	elapsed += dt
	shot.left = maxf(0.0, float(shot.left) - dt)
	for a: Dictionary in [player] + survivors + zombies:
		for key: String in ["cooldown", "flash", "swing"]:
			a[key] = maxf(0.0, float(a[key]) - dt)
	var travel: Vector2 = move_input * float(balance.player_speed) * Equipment.speed(self, player) * dt
	player.pos = routes.move(player.pos, player.pos + travel, travel.length())
	face_aim()
	Jobs.step(self, dt)
	Combat.step(self, dt)
	Territory.step(self, dt)
	Provisions.step(self, dt)
	var work_dt: float = dt * Provisions.work_rate(self)
	Neighbourhood.step(self, work_dt)
	_work(work_dt)
	Workshop.step(self, work_dt)
	Firearms.step(self, work_dt)
	Roadworks.step(self, work_dt)
	Pressure.step(self)
	SliceObjective.step(self, dt)
	var next_alert: String = "SAFE"
	for z: Dictionary in zombies:
		if float(z.hp) > 0 and z.pos.distance_to(Routes.point(balance.home_alert_center)) < float(balance.home_alert_radius):
			next_alert = "BREACHED" if float(properties.home.gate_hp) <= 0 or properties.home.open else "THREATENED"
	if next_alert != alert:
		alert = next_alert
		note("HOME / " + ("Gate area clear. Watch the street." if alert == "SAFE" else alert + ": check the gate and defender."))


func attack() -> void:
	Combat.strike(self, player, aim)


func shoot() -> bool:
	return Firearms.shoot(self)


func face_aim() -> void:
	if float(player.swing) <= 0 and not aim.is_zero_approx():
		player.facing = aim.normalized()


func remaining(id: String) -> int:
	var count: int = 0
	var rect: Rect2 = Routes.rectangle(definition(id).rect)
	for z: Dictionary in zombies:
		if float(z.hp) > 0 and rect.has_point(z.pos):
			count += 1
	return count


func connected(id: String) -> bool:
	if not properties.home.claimed:
		return false
	var reached: Array[String] = ["home"]
	var index: int = 0
	while index < reached.size():
		for next: String in definition(reached[index]).neighbors:
			if properties[next].claimed and not reached.has(next):
				reached.append(next)
		index += 1
	return reached.has(id)


func safe_connected(id: String) -> bool:
	return Neighbourhood.safe_connected(self, id)


func context() -> String:
	var text: String = _context()
	if not Salvage.nearby(self).is_empty():
		text += "   Q Timber (+%d materials)" % int(balance.timber_materials)
	return text


func salvage() -> bool:
	return Salvage.collect(self)


func _context() -> String:
	var passage: Dictionary = Neighbourhood.nearby(self)
	if not passage.is_empty():
		return Neighbourhood.context(self, passage)
	var defence: Dictionary = Roadworks.nearby(self)
	if not defence.is_empty():
		return Roadworks.context(self, defence)
	for p: Dictionary in catalog.properties:
		if player.pos.distance_to(Routes.point(p.gate)) < 76:
			if float(properties[p.id].gate_hp) <= 0:
				return "R Rebuild · %d materials" % int(balance.gate_repair_cost)
			return "E %s%s" % ["Close" if properties[p.id].open else "Open", "   R Repair · %d materials" % int(balance.gate_repair_cost) if float(properties[p.id].gate_hp) < float(balance.gate_health) else ""]
		if player.pos.distance_to(Routes.point(p.site)) < 85:
			if p.id == "home" and properties.home.claimed:
				var injured: bool = float(player.hp) < float(balance.player_health)
				for a: Dictionary in survivors:
					injured = injured or float(a.hp) < float(balance.survivor_health)
				if not injured:
					return ""
				return "E Recover · %d food" % int(balance.recovery_food)
			if remaining(p.id) > 0:
				return "Clear yard"
			if not properties[p.id].claimed:
				return "E Secure"
			if p.id == "munitions":
				return "F Bullets"
			if p.id == "garage":
				return Workshop.context(self)
			if p.id == "garden" and not garden_done:
				return "R Build   F Assign" if garden_started else WorkOrders.cost_prompt(self, "Garden", ["garden"], int(balance.garden_cost))
			if p.id == "garden":
				return "R Tend   F Assign"
			return ""
	return ""


func interact() -> void:
	var passage: Dictionary = Neighbourhood.nearby(self)
	if not passage.is_empty():
		Neighbourhood.interact(self, passage)
		return
	var defence: Dictionary = Roadworks.nearby(self)
	if not defence.is_empty():
		Roadworks.interact(self, defence)
		return
	for p: Dictionary in catalog.properties:
		var state: Dictionary = properties[p.id]
		if player.pos.distance_to(Routes.point(p.gate)) < 76:
			if float(state.gate_hp) <= 0:
				note("Gate destroyed. Hold R nearby to rebuild it.")
				return
			if state.open:
				for a: Dictionary in [player] + survivors + zombies:
					if (not a.has("raid") or float(a.hp) > 0) and absf(a.pos.x - float(p.gate[0])) < 60 and absf(a.pos.y - float(p.gate[1])) < 28:
						note("Gate is occupied. Step clear before closing it.")
						return
			state.open = not state.open
			rebuild_routes()
			return
		if player.pos.distance_to(Routes.point(p.site)) < 85:
			if p.id == "home" and state.claimed:
				Provisions.recover(self)
				return
			if not state.claimed:
				claim(p.id)
			elif p.id == "garage":
				Workshop.interact(self)
			elif p.id == "garden" and not garden_started:
				if Restoration.approve(self, "garden"):
					note("Garden approved. Hold R or assign a worker.")
			return


func claim(id: String) -> bool:
	if properties[id].claimed:
		return false
	if remaining(id) > 0:
		note("Clear the yard before securing this property.")
		return false
	var adjacent: bool = id == "home"
	for next: String in definition(id).neighbors:
		adjacent = adjacent or connected(next)
	if not adjacent:
		note("Secure a neighboring property first to connect this site to home.")
		return false
	properties[id].claimed = true
	properties[id].occupation = 0.0
	if properties[id].looted:
		note(definition(id).name + " / Reclaimed. Previous improvements preserved.")
		return true
	properties[id].looted = true
	food += int(definition(id).food_cache)
	materials += int(balance.claim_materials)
	if id == "garage":
		materials += int(balance.garage_bonus_materials)
		note("Garage recovered: tools, cached armour and %d extra materials. Restore the workshop here with E." % int(balance.garage_bonus_materials))
	elif id == "residence":
		Firearms.rescue(self)
	elif id == "munitions":
		note("Ammunition workshop unlocked. F assigns a worker: %d materials makes %d bullets in %ds." % [int(catalog.firearm.material_cost), int(catalog.firearm.batch_bullets), int(catalog.firearm.craft_seconds)])
	elif id == "library":
		var paige: Dictionary = actor("paige", "Paige", Routes.point(definition(id).site) + Vector2(35, 0), float(balance.survivor_health))
		paige.order = "Follow"
		Jobs.initialise(paige, "home")
		survivors.append(paige)
		note("Paige rescued. 'Next time, I want to be the one holding the door.'")
	else:
		note("Garden house secured. Start the food garden at its porch with E.")
	return true


func order(value: String) -> void:
	for a: Dictionary in survivors:
		if value == "Home":
			Jobs.resume(self, a)
		else:
			assign_survivor(a.id, "hold" if a.id == "ellis" and value == "Engage" else value.to_lower(), false)
	note("Team: " + value)


func assign_survivor(id: String, task: String, announce: bool = true) -> bool:
	return Tasks.assign(self, id, task, announce)


func assign_mara() -> void:
	# Compatibility for existing scenario scripts; live controls use named orders.
	var defence: Dictionary = Roadworks.nearby(self)
	if not defence.is_empty():
		assign_survivor("mara", "work:" + defence.id)
	elif Workshop.unfinished(self) and (player.pos.distance_to(Routes.point(definition("garage").site)) < 85 or not (garden_started and not garden_done)):
		assign_survivor("mara", "garage")
	elif garden_started and not garden_done:
		assign_survivor("mara", "garden")
	else:
		assign_survivor("mara", "home")


func _work(dt: float) -> void:
	for p: Dictionary in catalog.properties:
		var executor: String = "you" if working and player.pos.distance_to(Routes.point(p.gate)) < 76 else ""
		for a: Dictionary in survivors:
			if executor != "you" and a.order == "Repair" and a.job == p.id and float(a.hp) > 0 and a.pos.distance_to(Routes.point(p.gate)) < 40 and a.duty.clear_left <= 0:
				if executor.is_empty() or str(a.id) < executor:
					executor = a.id
		if executor.is_empty():
			Repairs.block(self, "gate:" + str(p.id), "Need worker at site")
		elif Repairs.step(self, "gate:" + str(p.id), executor, dt):
			for a: Dictionary in survivors:
				if a.order == "Repair" and a.job == p.id:
					Jobs.finish(self, a)
	if garden_started and not garden_done:
		if Restoration.step(self, "garden", dt):
			note("Garden ready. Hold R or assign a grower.")
			for a: Dictionary in survivors:
				if a.order in ["Build", "Garden"] and a.job == "garden":
					Jobs.finish(self, a)
	if garden_done and garden_tended() and safe_connected("garden") and not Combat.danger(self, Routes.point(definition("garden").site), 230):
		harvest += dt
		if harvest >= float(balance.food_seconds):
			harvest -= float(balance.food_seconds)
			food += int(balance.food_yield)
			provisions.harvested += int(balance.food_yield)


func post_road_guard() -> void:
	Roadworks.post_guard(self)


func garden_tended() -> bool:
	var site: Vector2 = Routes.point(definition("garden").site)
	if player_at_worksite("garden"):
		return true
	for a: Dictionary in survivors:
		if a.order == "Garden" and float(a.hp) > 0 and a.duty.clear_left <= 0 and a.pos.distance_to(site) < 40:
			return true
	return false


func player_at_worksite(id: String) -> bool:
	if not working or player.pos.distance_to(Routes.point(definition(id).site)) >= 85:
		return false
	for p: Dictionary in catalog.properties:
		if player.pos.distance_to(Routes.point(p.gate)) < 76:
			return false
	return true


func finish_job(a: Dictionary, cancelled: bool = false) -> void:
	if cancelled:
		Jobs.abort(self, a)
	else:
		Jobs.finish(self, a)
