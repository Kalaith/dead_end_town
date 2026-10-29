extends RefCounted
const Acoustics = preload("res://scripts/sim/noise.gd")
const Facility = preload("res://scripts/sim/facility.gd")
## Authoritative fixed-step state. Presentation sends commands only.
const FieldMedicine = preload("res://scripts/sim/field_medicine.gd")
const CompanionRescue = preload("res://scripts/sim/companion_rescue.gd")
const Medicine = preload("res://scripts/sim/medicine.gd")
const RecoverySalvage = preload("res://scripts/sim/recovery_salvage.gd")
const Defeat = preload("res://scripts/sim/defeat.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")
const Tips = preload("res://scripts/sim/tips.gd")
const HomeRest = preload("res://scripts/sim/home_rest.gd")
const FoodGrowing = preload("res://scripts/sim/food_growing.gd")
const Greenhouse = preload("res://scripts/sim/greenhouse.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")
const Discoveries = preload("res://scripts/sim/discoveries.gd")
const Roster = preload("res://scripts/sim/roster.gd")
const Exploration = preload("res://scripts/sim/exploration.gd")
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
const Boss = preload("res://scripts/sim/boss.gd")
const Tasks = preload("res://scripts/sim/tasks.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Workshop = preload("res://scripts/sim/workshop.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
var production: Dictionary
var noise: Dictionary = Acoustics.initial()
var memories: Dictionary = {}
var orders: Dictionary = WorkOrders.initial()
var firearms: Dictionary = Firearms.initial()
var shot: Dictionary = {"from": Vector2.ZERO, "to": Vector2.ZERO, "left": 0.0}
var roam_rng := RandomNumberGenerator.new()
var seen: Array = ["home"]
var catalog: Dictionary
## Id of the area being played; frozen holds the saved state of areas the player has left.
var area: String
var frozen: Dictionary = {}
var balance: Dictionary
var properties: Dictionary = {}
var player: Dictionary
var survivors: Array[Dictionary] = []
var zombies: Array[Dictionary] = []
var routes := Routes.new()
var materials: int
var food: int
var medicine: int = 0
var medicine_production: Dictionary
var growing: Dictionary = FoodGrowing.initial()
var greenhouse: Dictionary = Greenhouse.initial()
var clinic: Dictionary = Clinic.initial()
var rescue_intro: String = ""
var rescue_jobs: Dictionary = {}
var field_care: Dictionary = {}
var elapsed: float = 0.0
var approach: bool = false
var boss_seen_alive: bool = false
var exit_pending: float = 0.0
var unlocks: Array = []
var travel_requested: String = ""
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
var interacting: bool = false
var carry: Dictionary = Carrying.initial()
var vehicle: Dictionary
var tips: Dictionary
var spits: Array[Dictionary] = []
var spit_hits: Dictionary = {}
var home_rest: Dictionary = HomeRest.initial()
var recovery_salvage: Dictionary = RecoverySalvage.initial()
var alert: String = "SAFE"
var downs: int = 0
var defeat_pending: bool = false
var campaign_ended: bool = false
var workshop: Dictionary = Workshop.initial()
var timber: Dictionary = Salvage.initial()
var slice_state: Dictionary = SliceObjective.initial()
var provisions: Dictionary = Provisions.initial()
var equipment: Dictionary = Equipment.initial()
var passages: Dictionary
var roadworks: Dictionary
## What a held facility shows and does at its site, by facility id; each takes the world.
var facility_context: Dictionary = {"greenhouse": Greenhouse.context, "clinic": Clinic.context, "garage": Workshop.context, "munitions": func(_world: RefCounted) -> String: return "F Bullets", "garden": _garden_context}
var facility_interact: Dictionary = {"greenhouse": Greenhouse.approve, "clinic": _clinic_interact, "garage": Workshop.interact, "garden": _garden_interact}


func _init(data: Dictionary) -> void:
	catalog = data
	area = str(data.area.id)
	balance = data.balance
	production = Production.initial(data)
	medicine_production = Medicine.initial(data)
	roam_rng.seed = int(balance.roam_seed)
	passages = Neighbourhood.initial(data)
	vehicle = Vehicle.initial(data)
	roadworks = Roadworks.initial(data)
	pressure = Pressure.initial(data)
	materials = int(balance.starting_materials)
	food = int(balance.starting_food)
	player = actor("you", "You", Routes.point(balance.player_start), float(balance.player_health))
	tips = Tips.initial(self)
	Roster.start(self)
	for p: Dictionary in catalog.properties:
		properties[p.id] = {"claimed_once": p.id == "home", "claimed": p.id == "home", "looted": p.id == "home", "open": p.id != "home", "occupation": 0.0, "gate_hp": float(balance.gate_health) * (float(balance.home_gate_start_factor) if p.id == "home" else 1.0)}
		for spawn: Array in p.zombies:
			var z: Dictionary = actor("z%d" % zombies.size(), "Shambler", Routes.point(spawn), ZombieTypes.health(catalog))
			z.home = p.id
			z.raid = false
			zombies.append(z)
	Exploration.update(self)
	Pressure.add_residents(self)
	Boss.add(self)
	rebuild_routes()
	note("Mara has the gate. Hold R to repair.")


static func actor(id: String, label: String, pos: Vector2, hp: float) -> Dictionary:
	return {"id": id, "name": label, "pos": pos, "hp": hp, "cooldown": 0.0, "flash": 0.0, "swing": 0.0, "facing": Vector2.DOWN, "order": "Follow", "job": "", "anchor": pos, "activity": "Ready", "roam_angle": 0.0, "roam_left": 0.0}


func rebuild_routes() -> void:
	var defences: Array[Rect2] = []
	for d: Dictionary in catalog.barricades:
		if Roadworks.active(roadworks[d.id]):
			defences.append(Routes.rectangle(d.rect))
	# Water is impassable on foot and for the van, but not for globs or sight.
	for rect: Array in catalog.get("terrain", {}).get("water", []):
		defences.append(Routes.rectangle(rect))
	routes.rebuild(catalog.properties, properties, Routes.point(catalog.bounds), defences, Neighbourhood.openings(self), Neighbourhood.obstacles(self))


## A lot by id or by the facility it holds; {} when this area has none.
func definition(id: String) -> Dictionary:
	var lot: String = Facility.resolve(catalog, id)
	for p: Dictionary in catalog.properties:
		if p.id == lot:
			return p
	return {}


func note(message: String) -> void:
	messages.append(message)
	if messages.size() > 5:
		messages.pop_front()


func step(dt: float) -> void:
	if defeat_pending:
		return
	if float(player.hp) <= 0:
		Defeat.begin(self)
		return
	elapsed += dt
	Acoustics.age(self)
	shot.left = maxf(0.0, float(shot.left) - dt)
	for a: Dictionary in [player] + survivors + zombies:
		for key: String in ["cooldown", "flash", "swing"]:
			a[key] = maxf(0.0, float(a[key]) - dt)
	if Carrying.occupied(self) or Vehicle.driving(self):
		working = false
	var travel: Vector2 = move_input * float(balance.player_speed) * Equipment.speed(self, player) * (float(balance.carry_speed_factor) if Carrying.occupied(self) else 1.0) * dt
	if not Vehicle.driving(self):
		player.pos = routes.move(player.pos, player.pos + travel, travel.length())
	Vehicle.step(self, dt)
	Carrying.step(self, dt)
	face_aim()
	Exploration.update(self)
	Jobs.step(self, dt)
	CompanionRescue.step(self, dt)
	Combat.step(self, dt)
	CompanionRescue.sync(self)
	if float(player.hp) <= 0:
		Defeat.begin(self)
		return
	Territory.step(self, dt)
	Provisions.step(self, dt)
	HomeRest.step(self, dt)
	var work_dt: float = dt * Provisions.work_rate(self)
	var player_work: bool = working
	if not RecoverySalvage.nearby(self).is_empty():
		RecoverySalvage.step(self, work_dt)
		working = false
	if not FieldMedicine.player_target(self).is_empty():
		working = false
	Neighbourhood.step(self, work_dt)
	_work(work_dt)
	Vehicle.repair(self, work_dt)
	Workshop.step(self, work_dt)
	Clinic.step(self, work_dt)
	FoodGrowing.step(self, work_dt)
	Greenhouse.step(self, work_dt)
	Firearms.step(self, work_dt)
	Roadworks.step(self, work_dt)
	working = player_work
	FieldMedicine.step(self, work_dt)
	Pressure.step(self)
	Boss.step(self, dt)
	Tips.step(self, dt)
	Carrying.sync(self)
	CompanionRescue.sync(self)
	var next_alert: String = "SAFE"
	for z: Dictionary in zombies:
		if float(z.hp) > 0 and z.pos.distance_to(Routes.point(balance.home_alert_center)) < float(balance.home_alert_radius):
			next_alert = "BREACHED" if float(properties.home.gate_hp) <= 0 or properties.home.open else "THREATENED"
	if next_alert != alert:
		alert = next_alert
		note("HOME / " + ("Gate area clear. Watch the street." if alert == "SAFE" else alert + ": check the gate and defender."))


func attack() -> void:
	if Carrying.occupied(self) or Vehicle.driving(self):
		return
	Combat.strike(self, player, aim)


func shoot() -> bool:
	return false if Vehicle.driving(self) else Firearms.shoot(self)


func face_aim() -> void:
	if float(player.swing) <= 0 and not aim.is_zero_approx():
		player.facing = aim.normalized()


func remaining(id: String) -> int:
	var count: int = 0
	if definition(id).is_empty():
		return 0
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
	return reached.has(Facility.resolve(catalog, id))


func safe_connected(id: String) -> bool:
	return Neighbourhood.safe_connected(self, id)


func context() -> String:
	if _van_first():
		var drive_text: String = Vehicle.context(self)
		if not drive_text.is_empty():
			return drive_text
	var carry_text: String = Carrying.context(self)
	if not carry_text.is_empty():
		if not Carrying.occupied(self) and float(carry.progress) == 0:
			var service: String = _care_context()
			if not service.is_empty():
				var name: String = str(Carrying.nearby(self).name)
				return service + " · Hold E Carry" + ("" if service.contains(name) else " " + name)
		return carry_text
	var van_text: String = Vehicle.context(self)
	if not van_text.is_empty():
		return van_text
	var recovery_text: String = RecoverySalvage.context(self)
	if not recovery_text.is_empty():
		return recovery_text
	var field_text: String = FieldMedicine.context(self)
	if not field_text.is_empty():
		return field_text
	var text: String = _context()
	if not Salvage.nearby(self).is_empty():
		text += "   Q Timber (+%d materials)" % int(balance.timber_materials)
	return text


## The van takes the E press when driving, or when beside it with nothing nearer to lift or put down.
func _van_first() -> bool:
	if Vehicle.driving(self):
		return true
	if not Vehicle.near(self):
		return false
	return Carrying.shelter(self).is_empty() if Carrying.occupied(self) else Carrying.nearby(self).is_empty()


func salvage() -> bool:
	return false if Carrying.occupied(self) else Salvage.collect(self)


func _context() -> String:
	if not properties.home.claimed and player.pos.distance_to(Routes.point(balance.emergency_shelter)) < 50:
		return ""
	if Boss.at_exit(self):
		return Boss.context(self)
	if Boss.at_entrance(self):
		return Boss.entrance_context(self)
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
			if not p.available:
				return "Unfinished"
			if p.id == "home" and properties.home.claimed:
				return HomeRest.context(self)
			if remaining(p.id) > 0:
				return "Clear yard"
			if p.has("search") and not properties[p.id].looted:
				return "E Search"
			if not properties[p.id].claimed:
				return "E Secure"
			return str(facility_context[p.facility].call(self)) if facility_context.has(p.facility) else ""
	return ""


func interact() -> void:
	if float(player.hp) <= 0:
		return
	if _van_first() and Vehicle.press(self):
		return
	if Carrying.press(self):
		return
	if Boss.at_exit(self):
		Boss.interact(self)
		return
	if Boss.at_entrance(self):
		Boss.enter_interact(self)
		return
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
						# A downed survivor still blocks the gate: they must be carried clear, not shut in or out.
						note("%s is down in the gateway. Carry them clear before closing it." % a.name if float(a.hp) <= 0 else "Gate is occupied. Step clear before closing it.")
						return
			state.open = not state.open
			rebuild_routes()
			return
		if player.pos.distance_to(Routes.point(p.site)) < 85:
			if p.id == "home" and state.claimed:
				Provisions.recover(self)
				return
			if p.has("search") and not state.looted:
				Discoveries.search(self, p.id)
			elif not state.claimed:
				claim(p.id)
			elif facility_interact.has(p.facility):
				facility_interact[p.facility].call(self)
			return


func _garden_context(_world: RefCounted) -> String:
	if garden_done:
		return "R Tend · %d%%   F Assign" % int(100 * harvest / float(balance.food_seconds))
	return "R Build   F Assign" if garden_started else WorkOrders.cost_prompt(self, "Garden", ["garden"], int(balance.garden_cost))


func _clinic_interact(_world: RefCounted) -> void:
	if clinic.done:
		Clinic.treat(self)
	else:
		Clinic.approve(self)


func _garden_interact(_world: RefCounted) -> void:
	if not garden_started and Restoration.approve(self, "garden"):
		note("Garden approved. Hold R or assign a worker.")


func claim(id: String) -> bool:
	if not definition(id).available:
		note("This part of town is still in development.")
		return false
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
	var p: Dictionary = definition(id)
	if p.has("search") and (float(player.hp) <= 0 or player.pos.distance_to(Routes.point(p.site)) >= 85):
		return false
	if p.has("search") and not properties[id].looted:
		note("Search the site before securing it.")
		return false
	var first: bool = not properties[id].claimed_once
	properties[id].claimed = true
	properties[id].claimed_once = true
	properties[id].occupation = 0.0
	Pressure.claimed(self, id)
	if p.has("search"):
		if first:
			materials += int(balance.claim_materials)
		note(p.name + (" secured." if first else " reclaimed."))
		return true
	if properties[id].looted:
		note(definition(id).name + " / Reclaimed. Previous improvements preserved.")
		return true
	properties[id].looted = true
	food += int(definition(id).food_cache)
	materials += int(balance.claim_materials)
	if Facility.kind_of(catalog, id) == "garage":
		materials += int(balance.garage_bonus_materials)
		note("Garage recovered: tools, cached armour and %d extra materials. Restore the workshop here with E." % int(balance.garage_bonus_materials))
	elif Facility.kind_of(catalog, id) == "residence":
		Firearms.rescue(self)
	elif Facility.kind_of(catalog, id) == "munitions":
		note("Ammunition workshop unlocked. F assigns a worker: %d materials makes %d bullets in %ds." % [int(catalog.firearm.material_cost), int(catalog.firearm.batch_bullets), int(catalog.firearm.craft_seconds)])
	elif Facility.kind_of(catalog, id) == "library":
		Roster.recruit(self, "paige")
	else:
		note("Garden house secured. Start the food garden at its porch with E.")
	return true


func order(value: String) -> void:
	tips.ordered = true
	for a: Dictionary in survivors:
		if a.order == "Rescue":
			continue
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



func post_road_guard() -> void:
	Roadworks.post_guard(self)


func garden_tended() -> bool:
	if definition("garden").is_empty():
		return false
	var site: Vector2 = Routes.point(definition("garden").site)
	if player_at_worksite("garden"):
		return true
	for a: Dictionary in survivors:
		if a.order == "Garden" and float(a.hp) > 0 and a.duty.clear_left <= 0 and a.pos.distance_to(site) < 40:
			return true
	return false


func player_at_worksite(id: String) -> bool:
	if definition(id).is_empty() or Carrying.occupied(self) or float(player.hp) <= 0 or not working or player.pos.distance_to(Routes.point(definition(id).site)) >= 85:
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


func release_interact() -> void:
	if not Carrying.release(self) or float(player.hp) <= 0:
		return
	if HomeRest.at_porch(self) and properties.home.claimed:
		HomeRest.start(self)
	elif clinic.done and player.pos.distance_to(Routes.point(definition("clinic").site)) < 85:
		Clinic.treat(self)


func _care_context() -> String:
	if HomeRest.at_porch(self) and properties.home.claimed:
		return HomeRest.context(self)
	if clinic.done and Facility.state(self, "clinic").claimed and player.pos.distance_to(Routes.point(definition("clinic").site)) < 85:
		return Clinic.context(self)
	return ""


func abandon_carried() -> void:
	Carrying.abandon(self)
