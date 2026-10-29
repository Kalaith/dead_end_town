extends RefCounted
## Upgrades older saves one schema at a time; each step feeds the next until the current schema is reached and validated.
const ScreecherState = preload("res://scripts/core/screecher_state.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")
const Acoustics = preload("res://scripts/sim/noise.gd")
const RunnerState = preload("res://scripts/core/runner_state.gd")
const ResidentState = preload("res://scripts/core/resident_state.gd")
const Medicine = preload("res://scripts/sim/medicine.gd")
const RecoverySalvage = preload("res://scripts/sim/recovery_salvage.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
const HomeRest = preload("res://scripts/sim/home_rest.gd")
const Greenhouse = preload("res://scripts/sim/greenhouse.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")
const TownState = preload("res://scripts/core/town_state.gd")
const JobState = preload("res://scripts/core/job_state.gd")
const RepairState = preload("res://scripts/core/repair_state.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Production = preload("res://scripts/sim/production.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Salvage = preload("res://scripts/sim/salvage.gd")
const SliceObjective = preload("res://scripts/sim/slice_objective.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const PressureState = preload("res://scripts/core/pressure_state.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const World = preload("res://scripts/sim/world.gd")
const Workshop = preload("res://scripts/sim/workshop.gd")
var catalog: Dictionary
## The owning SaveState is held weakly: it owns this object, and a strong link back would leak both.
var _owner: WeakRef
var save: RefCounted:
	get:
		return _owner.get_ref()


func _init(data: Dictionary, owner: RefCounted) -> void:
	catalog = data
	_owner = weakref(owner)


func migrate(data: Dictionary) -> Dictionary:
	if not Rules.integer_in(data.get("schema_version"), 1, save.SCHEMA - 1):
		return {}
	var upgraded: Dictionary = data.duplicate(true)
	var version: int = int(upgraded.schema_version)
	if not TownState.expand(upgraded, catalog):
		return {}
	if version == 41:
		return _upgrade_fittings(upgraded)
	if version == 40:
		return _upgrade_vehicle(upgraded)
	if version == 38 or version == 39:
		return _upgrade_residents(upgraded)
	if version == 37:
		return _upgrade_unlocks(upgraded)
	if version == 36:
		return _upgrade_boss(upgraded)
	if version == 35:
		return _upgrade_areas(upgraded)
	if version == 34:
		return _upgrade_campaign_pressure(upgraded)
	if version == 33:
		return _upgrade_screechers(upgraded)
	if version == 32:
		return _upgrade_attention(upgraded)
	if version == 31:
		return _upgrade_runners(upgraded)
	if version == 30:
		return _upgrade_greenhouse_work(upgraded)
	if version == 29:
		return _upgrade_greenhouse_search(upgraded)
	if version == 28:
		return _upgrade_field_medicine(upgraded)
	if version == 27:
		return _upgrade_companion_rescue(upgraded)
	if version == 26:
		return _upgrade_medicine(upgraded)
	if version == 25:
		return _upgrade_recovery_salvage(upgraded)
	if version == 24:
		return _upgrade_defeat(upgraded)
	if version == 23:
		return _upgrade_recovery(upgraded)
	if version == 22:
		return _upgrade_clinic_work(upgraded)
	if version == 21:
		return _upgrade_clinic_search(upgraded)
	if version == 20:
		return _upgrade_discoveries(upgraded)
	if version == 19:
		return _upgrade_town(upgraded)
	if version == 18:
		return _upgrade_jobs(upgraded)
	if version == 17:
		return _upgrade_repairs(upgraded)
	if version == 16:
		return _upgrade_road_orders(upgraded)
	if version == 15:
		return _upgrade_restoration_orders(upgraded)
	if version == 14:
		return _upgrade_passage_orders(upgraded)
	if version == 13:
		return _upgrade_production(upgraded)
	if version == 12:
		return _upgrade_orders(upgraded)
	if version == 11:
		return _upgrade_firearms(upgraded)
	if version == 10:
		return _upgrade_slice(upgraded)
	if version == 9:
		return _upgrade_provisions(upgraded)
	if version == 8:
		return _upgrade_equipment(upgraded)
	if version == 7:
		return _upgrade_neighbourhood(upgraded)
	if version == 6:
		return _upgrade_roaming(upgraded)
	if version == 5:
		return _upgrade_territory(upgraded)
	if version == 1:
		upgraded.workshop = Workshop.initial()
		upgraded.mara_site = "garden"
	if version <= 2:
		upgraded.roadworks = Roadworks.initial(catalog)
		upgraded.road_job = ""
	if version == 4:
		return _upgrade_pressure(upgraded)
	if upgraded.get("mara_site") not in ["garden", "garage"] or not upgraded.get("road_job") is String:
		return {}
	if not upgraded.get("player") is Dictionary or not upgraded.get("survivors") is Array or not upgraded.get("zombies") is Array:
		return {}
	for a: Variant in [upgraded.player] + upgraded.survivors + upgraded.zombies:
		if not a is Dictionary:
			return {}
		a.job = ""
		if a.get("order") == "Build":
			a.job = upgraded.mara_site
		elif a.get("order") == "Roadwork":
			a.job = upgraded.road_job
	upgraded.erase("mara_site")
	upgraded.erase("road_job")
	return _upgrade_pressure(upgraded)


func _upgrade_pressure(data: Dictionary) -> Dictionary:
	if not data.get("zombies") is Array or not data.get("properties") is Dictionary or not data.get("approach") is bool or not Rules.finite(data.get("elapsed")):
		return {}
	# Preserve old residents and cleared yards. Only previously unclaimed yards gain occupants.
	var fresh := World.new(catalog)
	var ids: Array[String] = []
	for z: Variant in data.zombies:
		if not z is Dictionary or not z.get("id") is String:
			return {}
		ids.append(z.id)
	for z: Dictionary in fresh.zombies:
		if z.id.begins_with("resident_") and not ids.has(z.id):
			if not data.properties.get(z.home) is Dictionary or not data.properties[z.home].get("claimed") is bool:
				return {}
			if data.properties[z.home].claimed:
				z.hp = 0.0
			data.zombies.append(save.encode_actor(z))
	data.pressure = {"wave": 0, "next": 0.0, "warned": false}
	data.pressure.wave = 1 if data.approach else 0
	# Loading old progress gives a preparation interval, never an immediate overdue wave.
	data.pressure.next = float(data.elapsed) + 65.0
	data.schema_version = 5
	return _upgrade_territory(data)


func _upgrade_territory(data: Dictionary) -> Dictionary:
	if not data.get("properties") is Dictionary:
		return {}
	for p: Variant in data.properties.values():
		if not p is Dictionary:
			return {}
		p.occupation = 0.0
	data.schema_version = 6
	return _upgrade_roaming(data)


func _upgrade_roaming(data: Dictionary) -> Dictionary:
	if not data.get("player") is Dictionary or not data.get("survivors") is Array or not data.get("zombies") is Array:
		return {}
	for a: Variant in [data.player] + data.survivors + data.zombies:
		if not a is Dictionary:
			return {}
		a.roam_angle = 0.0
		a.roam_left = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(catalog.balance.roam_seed)
	data.roam_rng_state = str(rng.state)
	data.schema_version = 7
	return _upgrade_neighbourhood(data)


func _upgrade_neighbourhood(data: Dictionary) -> Dictionary:
	data.passages = Neighbourhood.initial(catalog)
	data.schema_version = 8
	return _upgrade_equipment(data)


func _upgrade_equipment(data: Dictionary) -> Dictionary:
	if not data.get("workshop") is Dictionary or not data.workshop.get("equipped") is bool:
		return {}
	data.equipment = Equipment.initial()
	if data.workshop.equipped:
		data.equipment.iron = "paige"
		data.equipment.shield = "paige"
	data.schema_version = 9
	return _upgrade_provisions(data)


func _upgrade_provisions(data: Dictionary) -> Dictionary:
	data.provisions = Provisions.initial()
	data.schema_version = 10
	return _upgrade_slice(data)


func _upgrade_slice(data: Dictionary) -> Dictionary:
	data.gate_repair_target = "home"
	data.timber = Salvage.initial()
	data.slice_state = SliceObjective.initial()
	data.schema_version = 11
	return _upgrade_firearms(data)


func _upgrade_firearms(data: Dictionary) -> Dictionary:
	if not data.get("properties") is Dictionary or not data.get("passages") is Dictionary or not data.get("zombies") is Array:
		return {}
	var fresh := World.new(catalog)
	for id: String in ["residence", "munitions"]:
		if data.properties.has(id):
			continue
		data.properties[id] = fresh.properties[id].duplicate(true)
		for z: Dictionary in fresh.zombies:
			if z.home == id:
				data.zombies.append(save.encode_actor(z))
	for id: String in fresh.passages:
		if not data.passages.has(id):
			data.passages[id] = fresh.passages[id].duplicate(true)
	data.firearms = {"owned": false, "bullets": 0, "progress": 0.0, "reserved": false}
	data.schema_version = 12
	return _upgrade_orders(data)


func _upgrade_orders(data: Dictionary) -> Dictionary:
	if not data.get("firearms") is Dictionary:
		return {}
	var s: Dictionary = data.firearms
	if not s.get("reserved") is bool or not Rules.finite(s.get("progress")):
		return {}
	if float(s.progress) < 0 or float(s.progress) >= float(catalog.firearm.craft_seconds) or (float(s.progress) > 0 and not s.reserved):
		return {}
	data.orders = WorkOrders.initial()
	if s.reserved:
		var recipe: Dictionary = {"id": "bullets", "kind": "production", "inputs": {"materials": int(catalog.firearm.material_cost)}, "outputs": {"bullets": int(catalog.firearm.batch_bullets)}, "seconds": float(catalog.firearm.craft_seconds)}
		var site: Array = []
		for p: Dictionary in catalog.properties:
			if p.facility == "munitions":
				site = p.site
		data.orders.sequence = 1
		data.orders.sites.munitions = WorkOrders.record(1, "munitions", "munitions", recipe, Vector2(float(site[0]), float(site[1])))
		data.orders.sites.munitions.work_done = float(s.progress)
	s.erase("reserved")
	s.erase("progress")
	data.schema_version = 13
	return _upgrade_production(data)


func _upgrade_production(data: Dictionary) -> Dictionary:
	data.production = Production.initial(catalog)
	if data.get("survivors") is Array:
		for a: Variant in data.survivors:
			if a is Dictionary and a.get("order") == "Ammo":
				data.production.mode = "repeat"
	data.schema_version = 14
	return _upgrade_passage_orders(data)


func _upgrade_passage_orders(data: Dictionary) -> Dictionary:
	if not data.get("passages") is Dictionary or not data.get("orders") is Dictionary or not data.orders.get("sites") is Dictionary or not Rules.integer_in(data.orders.get("sequence"), 0, 1000000000):
		return {}
	for d: Dictionary in catalog.passages:
		var s: Variant = data.passages.get(d.id)
		if not s is Dictionary or not s.get("started") is bool or not s.get("done") is bool:
			return {}
		if s.started and not s.done:
			if not Rules.finite(s.get("progress")):
				return {}
			data.orders.sequence = int(data.orders.sequence) + 1
			var order: Dictionary = WorkOrders.record(int(data.orders.sequence), "passage:" + str(d.id), d.id, Neighbourhood.recipe(catalog), Routes.point(d.sites[0]))
			order.work_done = float(s.progress)
			data.orders.sites[order.socket] = order
	data.schema_version = 15
	return _upgrade_restoration_orders(data)


func _upgrade_restoration_orders(data: Dictionary) -> Dictionary:
	if not data.get("orders") is Dictionary or not data.orders.get("sites") is Dictionary or not Rules.integer_in(data.orders.get("sequence"), 0, 1000000000) or not data.get("workshop") is Dictionary:
		return {}
	for id: String in ["garden", "workshop", "armour"]:
		var keys: Array = ["started", "done", "progress"] if id == "workshop" else ["armour_started", "armour_done", "armour_progress"]
		var s: Dictionary = {"started": data.get("garden_started"), "done": data.get("garden_done"), "progress": data.get("garden_progress")} if id == "garden" else {"started": data.workshop.get(keys[0]), "done": data.workshop.get(keys[1]), "progress": data.workshop.get(keys[2])}
		if not s.started is bool or not s.done is bool or not Rules.finite(s.progress):
			return {}
		if s.started and not s.done:
			data.orders.sequence = int(data.orders.sequence) + 1
			var site_id: String = "garden" if id == "garden" else "garage"
			var stand := Vector2.ZERO
			for p: Dictionary in catalog.properties:
				if p.id == site_id:
					stand = Routes.point(p.site)
			var order: Dictionary = WorkOrders.record(int(data.orders.sequence), "restore:" + id, site_id, WorkRecipes.recipe(catalog, id), stand)
			order.work_done = float(s.progress)
			data.orders.sites[order.socket] = order
	data.schema_version = 16
	return _upgrade_road_orders(data)


func _upgrade_road_orders(data: Dictionary) -> Dictionary:
	if not data.get("orders") is Dictionary or not data.orders.get("sites") is Dictionary or not Rules.integer_in(data.orders.get("sequence"), 0, 1000000000) or not data.get("roadworks") is Dictionary:
		return {}
	for d: Dictionary in catalog.barricades:
		var s: Variant = data.roadworks.get(d.id)
		if not s is Dictionary:
			return {}
		if s.get("phase") in ["building", "dismantling"]:
			if not Rules.finite(s.get("progress")):
				return {}
			data.orders.sequence = int(data.orders.sequence) + 1
			var recipe_id: String = "road_build" if s.phase == "building" else "road_remove"
			var order: Dictionary = WorkOrders.record(int(data.orders.sequence), "road:" + str(d.id), d.id, WorkRecipes.recipe(catalog, recipe_id), Routes.point(d.site))
			order.work_done = float(s.progress)
			data.orders.sites[order.socket] = order
	data.schema_version = 17
	return _upgrade_repairs(data)


func _upgrade_repairs(data: Dictionary) -> Dictionary:
	if not RepairState.migrate(data, catalog):
		return {}
	data.schema_version = 18
	return _upgrade_jobs(data)


func _upgrade_jobs(data: Dictionary) -> Dictionary:
	if not JobState.migrate(data, catalog):
		return {}
	data.schema_version = 19
	return _upgrade_town(data)


func _upgrade_town(data: Dictionary) -> Dictionary:
	data.seen = TownState.LEGACY.duplicate()
	data.schema_version = 20
	return _upgrade_discoveries(data)


func _upgrade_discoveries(data: Dictionary) -> Dictionary:
	if not data.get("properties") is Dictionary or not data.get("equipment") is Dictionary or not data.get("zombies") is Array:
		return {}
	for state: Variant in data.properties.values():
		if not state is Dictionary or not state.get("looted") is bool:
			return {}
		state.claimed_once = state.looted
	if not data.equipment.has("spear"):
		data.equipment.spear = ""
	# Add only newly implemented residents; existing actors and cleared corpses stay exact.
	var ids: Array[String] = []
	for z: Variant in data.zombies:
		if not z is Dictionary or not z.get("id") is String:
			return {}
		ids.append(z.id)
	var fresh := World.new(catalog)
	for z: Dictionary in fresh.zombies:
		if z.home == "hardware" and z.id not in ids:
			data.zombies.append(save.encode_actor(z))
	data.schema_version = 21
	return _upgrade_clinic_search(data)


func _upgrade_clinic_search(data: Dictionary) -> Dictionary:
	if not data.get("zombies") is Array:
		return {}
	data.medicine = 0
	data.rescue_intro = ""
	var ids: Array[String] = []
	for z: Variant in data.zombies:
		if not z is Dictionary or not z.get("id") is String:
			return {}
		ids.append(z.id)
	var fresh := World.new(catalog)
	for z: Dictionary in fresh.zombies:
		if z.home == "clinic" and z.id not in ids:
			data.zombies.append(save.encode_actor(z))
	data.schema_version = 22
	return _upgrade_clinic_work(data)


func _upgrade_clinic_work(data: Dictionary) -> Dictionary:
	data.clinic = Clinic.initial()
	data.schema_version = 23
	return _upgrade_recovery(data)


func _upgrade_recovery(data: Dictionary) -> Dictionary:
	data.carry = Carrying.initial()
	data.home_rest = HomeRest.initial()
	data.schema_version = 24
	return _upgrade_defeat(data)


func _upgrade_defeat(data: Dictionary) -> Dictionary:
	data.defeat_pending = false
	data.schema_version = 25
	return _upgrade_recovery_salvage(data)


func _upgrade_recovery_salvage(data: Dictionary) -> Dictionary:
	data.recovery_salvage = RecoverySalvage.initial()
	data.schema_version = 26
	return _upgrade_medicine(data)


func _upgrade_medicine(data: Dictionary) -> Dictionary:
	data.medicine_production = Medicine.initial(catalog)
	data.schema_version = 27
	return _upgrade_companion_rescue(data)


func _upgrade_companion_rescue(data: Dictionary) -> Dictionary:
	data.rescue_jobs = {}
	data.schema_version = 28
	return _upgrade_field_medicine(data)


func _upgrade_field_medicine(data: Dictionary) -> Dictionary:
	if not data.get("equipment") is Dictionary:
		return {}
	if not data.equipment.has("field_bag"):
		data.equipment.field_bag = ""
	data.field_care = {}
	data.schema_version = 29
	return _upgrade_greenhouse_search(data)


func _upgrade_greenhouse_search(data: Dictionary) -> Dictionary:
	if not data.get("zombies") is Array:
		return {}
	var ids: Array[String] = []
	for z: Variant in data.zombies:
		if not z is Dictionary or not z.get("id") is String:
			return {}
		ids.append(z.id)
	var fresh := World.new(catalog)
	for z: Dictionary in fresh.zombies:
		if z.home == "greenhouse" and z.id not in ids:
			data.zombies.append(save.encode_actor(z))
	data.schema_version = 30
	return _upgrade_greenhouse_work(data)


func _upgrade_greenhouse_work(data: Dictionary) -> Dictionary:
	data.greenhouse = Greenhouse.initial()
	data.growing = {"garden": false, "greenhouse": false}
	if not Rules.finite(data.get("harvest")) or not data.get("provisions") is Dictionary or not Rules.finite(data.provisions.get("clock")):
		return {}
	# Preserve the fraction of the old 20-second harvest and 60-second meal clocks.
	data.harvest = float(data.harvest) / 20.0 * float(catalog.balance.food_seconds)
	data.provisions.clock = float(data.provisions.clock) / 60.0 * float(catalog.balance.meal_seconds)
	return _upgrade_runners(data)


func _upgrade_runners(data: Dictionary) -> Dictionary:
	if not RunnerState.migrate(data, catalog):
		return {}
	return _upgrade_attention(data)


func _upgrade_attention(data: Dictionary) -> Dictionary:
	data.noise = Acoustics.initial()
	data.memories = {}
	return _upgrade_screechers(data)


func _upgrade_screechers(data: Dictionary) -> Dictionary:
	if not ScreecherState.migrate(data, catalog):
		return {}
	return _upgrade_campaign_pressure(data)


func _upgrade_campaign_pressure(data: Dictionary) -> Dictionary:
	if not PressureState.migrate(data, catalog):
		return {}
	data.schema_version = 35
	return _upgrade_areas(data)


## Saves before areas were one street; it becomes the first area with nothing frozen.
func _upgrade_areas(data: Dictionary) -> Dictionary:
	data.area = catalog.area.id
	data.frozen = {}
	return _upgrade_boss(data)


## Saves before the boss gain it and its escorts at their posts.
func _upgrade_boss(data: Dictionary) -> Dictionary:
	return _upgrade_unlocks(data)


## Saves before travel have nothing unlocked elsewhere.
func _upgrade_unlocks(data: Dictionary) -> Dictionary:
	data.unlocks = []
	return _upgrade_residents(data)


## Saves before the doubled yards and the boss gain every resident they lack, at its authored post.
func _upgrade_residents(data: Dictionary) -> Dictionary:
	if not ResidentState.renumber(data, catalog):
		return {}
	# Short-term memories are keyed by zombie id, and ids may have just changed.
	data.memories = {}
	var ids: Array = data.zombies.map(func(z: Dictionary) -> String: return str(z.id))
	for z: Dictionary in World.new(catalog).zombies:
		if not z.raid and z.id not in ids:
			data.zombies.append(save.encode_actor(z))
	return _upgrade_vehicle(data)


## Saves before the van: it starts where the area places it, undriven.
func _upgrade_vehicle(data: Dictionary) -> Dictionary:
	data.vehicle = Vehicle.initial(catalog)
	return _upgrade_fittings(data)


## Saves before riders, van repair and saved spit hazards have none of them.
func _upgrade_fittings(data: Dictionary) -> Dictionary:
	if data.get("vehicle") is Dictionary:
		data.vehicle.riders = []
		data.vehicle.repair_paid = false
		data.vehicle.repair_progress = 0.0
	data.spits = []
	data.spit_hits = {}
	data.schema_version = save.SCHEMA
	return data if save.valid(data) else {}
