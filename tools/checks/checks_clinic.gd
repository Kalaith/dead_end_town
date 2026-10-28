extends RefCounted
const Clinic = preload("res://scripts/sim/clinic.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Roster = preload("res://scripts/sim/roster.gd")
const Discoveries = preload("res://scripts/sim/discoveries.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const DiscoveryChecks = preload("res://tools/checks/checks_discoveries.gd")


static func prepared() -> RefCounted:
	var w: RefCounted = DiscoveryChecks.prepared()
	w.player.pos = Vector2(3240, 350)
	Discoveries.search(w, "clinic")
	return w


func check_june_search_pays_once_before_claim_and_intro_survives_json_reload() -> String:
	var w: RefCounted = DiscoveryChecks.prepared()
	var materials: int = w.materials
	var food: int = w.food
	w.player.pos = Vector2(3240, 350)
	if not Discoveries.search(w, "clinic") or w.medicine != 12 or w.materials != materials + 12 or w.food != food + 4 or w.properties.clinic.claimed:
		return "Clinic search did not commit its separate finite rewards."
	if w.rescue_intro != "june" or Roster.person(w, "june").order != "Hold" or Discoveries.search(w, "clinic"):
		return "Clinic rescue did not create one held recruit/introduction."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.rescue_intro != "june" or loaded.medicine != 12 or Roster.dismiss(loaded, "home"):
		return "Pending rescue reload or unsafe home choice failed."
	if not Roster.dismiss(loaded, "follow") or not loaded.rescue_intro.is_empty() or Roster.person(loaded, "june").order != "Follow":
		return "Rescue choice did not issue the ordinary survivor command."
	return "Repeated intro changed duty" if Roster.dismiss(loaded, "hold") else ""


func check_june_uses_shared_equipment_and_counts_for_the_next_meal() -> String:
	var w: RefCounted = prepared()
	w.player.pos = Vector2(1080, 800)
	var june: Dictionary = Roster.person(w, "june")
	june.pos = w.player.pos
	if not Equipment.equip(w, "june", "weapon", "spear") or Equipment.equip(w, "mara", "weapon", "spear"):
		return "June bypassed unique equipment or cannot use ordinary equipment."
	var cost: int = 1 + w.survivors.size()
	w.food = cost
	w.provisions.clock = float(w.balance.meal_seconds) - 0.05
	w.step(0.05)
	return "June did not join the next shared meal" if w.food != 0 else ""


func check_schema_twenty_one_preserves_search_claim_split_and_adds_only_clinic_residents() -> String:
	var w: RefCounted = DiscoveryChecks.prepared()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 21
	old.erase("medicine")
	old.erase("rescue_intro")
	var prior: Array = []
	for z: Dictionary in old.zombies:
		if z.home != "clinic":
			prior.append(z)
	old.zombies = prior.duplicate(true)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.medicine != 0 or not loaded.rescue_intro.is_empty() or loaded.properties.hardware.claimed_once or not loaded.properties.hardware.looted:
		return "Schema twenty-one changed search history or granted a rescue."
	var result: Dictionary = save.snapshot(loaded)
	if result.zombies.slice(0, prior.size()) != prior or result.zombies.size() != prior.size() + 3 or loaded.roam_rng.state != w.roam_rng.state or loaded.materials != w.materials:
		return "Clinic migration changed existing actors, RNG or supplies."
	var bad: Dictionary = save.snapshot(loaded)
	bad.rescue_intro = "june"
	return "Unrescued introduction passed validation" if save.valid(bad) else ""


static func connected_clinic(restore: bool = true) -> RefCounted:
	var w: RefCounted = prepared()
	Roster.dismiss(w, "hold")
	w.claim("residence")
	w.player.pos = Vector2(2520, 350)
	w.claim("hardware")
	w.player.pos = Vector2(3240, 350)
	w.claim("clinic")
	for d: Dictionary in w.catalog.passages:
		if d.requires[0] in ["home", "garden", "residence", "hardware", "clinic"] and d.requires[1] in ["home", "garden", "residence", "hardware", "clinic"]:
			w.passages[d.id] = {"started": true, "done": true, "progress": float(w.balance.passage_seconds), "hp": float(w.balance.gate_health), "open": true, "repair_reserved": false}
	w.rebuild_routes()
	w.materials = 100
	if restore:
		Clinic.approve(w)
		w.working = true
		Clinic.step(w, float(w.balance.clinic_seconds))
	w.working = false
	return w


func check_clinic_restoration_is_paid_shared_cancellable_and_resumes_regular_duty() -> String:
	var w: RefCounted = prepared()
	Roster.dismiss(w, "hold")
	if Clinic.approve(w):
		return "Unclaimed clinic approved restoration."
	w.claim("residence")
	w.player.pos = Vector2(2520, 350)
	w.claim("hardware")
	w.player.pos = Vector2(3240, 350)
	w.claim("clinic")
	var stock: int = w.materials
	if not Clinic.approve(w) or w.materials != stock - 12 or Clinic.approve(w):
		return "Clinic restoration did not commit twelve materials once."
	w.assign_survivor("june", "clinic")
	w.working = true
	Clinic.step(w, 5.0)
	if w.clinic.progress != 5.0:
		return "Player and June doubled clinic work."
	w.properties.clinic.claimed = false
	Clinic.step(w, 100.0)
	if w.clinic.progress != 5.0 or w.clinic.done:
		return "Lost clinic completed restoration."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.clinic.progress != 5.0:
		return "Paid clinic restoration failed JSON reload."
	stock = loaded.materials
	if not Clinic.cancel(loaded, "restore:clinic") or loaded.materials != stock + 11 or loaded.clinic.started or Clinic.cancel(loaded, "restore:clinic"):
		return "Clinic cancellation return was incorrect or repeatable."
	return "Cancelled clinic remained assigned" if Roster.person(loaded, "june").order != "Idle" else ""


func check_treatment_needs_present_patient_and_worker_and_never_heals_remotely() -> String:
	var w: RefCounted = connected_clinic()
	if not w.clinic.done or not w.safe_connected("clinic"):
		return "Clinic fixture failed to build a physical protected route."
	var june: Dictionary = Roster.person(w, "june")
	june.hp = 0.0
	june.pos = Vector2(2520, 350)
	var medicine: int = w.medicine
	if Clinic.treat(w) or w.medicine != medicine:
		return "Clinic charged for a remote casualty."
	june.pos = Vector2(3275, 350)
	if not Clinic.treat(w) or Clinic.treat(w) or w.medicine != medicine - 1:
		return "Treatment did not commit one medicine once."
	Clinic.step(w, 10.0)
	if june.hp != 0 or w.clinic.patients.june.progress != 0:
		return "Clinic progressed without a worker."
	w.working = true
	Clinic.step(w, 4.0)
	w.properties.clinic.claimed = false
	Clinic.step(w, 20.0)
	if june.hp != 0 or w.clinic.patients.june.progress != 4.0:
		return "Lost clinic progressed treatment."
	w.claim("clinic")
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Paid patient failed reload."
	loaded.working = true
	Clinic.step(loaded, 6.0)
	var recovered: Dictionary = Roster.person(loaded, "june")
	if recovered.hp != 100 or not loaded.clinic.patients.is_empty() or loaded.medicine != medicine - 1:
		return "Clinic did not revive the present patient once."
	return "Healthy patient spent medicine" if Clinic.treat(loaded) else ""


func check_clinic_survivor_works_physically_and_danger_disconnect_preserve_treatment() -> String:
	var w: RefCounted = connected_clinic()
	var june: Dictionary = Roster.person(w, "june")
	june.pos = Vector2(2520, 350)
	w.assign_survivor("june", "clinic")
	w.player.hp = 30.0
	Clinic.treat(w)
	Clinic.step(w, 10.0)
	if w.player.hp != 30 or w.clinic.patients.you.progress != 0:
		return "Remote clinic worker healed a patient."
	for i: int in range(160):
		w.step(0.05)
	if june.pos.distance_to(Vector2(3240, 350)) > 40 or float(w.clinic.patients.you.progress) <= 0:
		return "Clinic worker failed to walk to the patient."
	var before: float = w.clinic.patients.you.progress
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = Vector2(3320, 400)
	Clinic.step(w, 5.0)
	if w.clinic.patients.you.progress != before:
		return "Danger advanced treatment."
	w.zombies[0].hp = 0.0
	w.properties.home.claimed = false
	Clinic.step(w, 5.0)
	return "Disconnected treatment advanced" if w.clinic.patients.you.progress != before else ""


func check_schema_twenty_two_keeps_medicine_and_intro_without_free_clinic() -> String:
	var w: RefCounted = prepared()
	w.medicine = 7
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 22
	old.erase("clinic")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.medicine != 7 or loaded.rescue_intro != "june" or loaded.clinic.started or loaded.clinic.done or not loaded.clinic.patients.is_empty():
		return "Schema twenty-two granted a clinic or lost rescue/supplies."
	var bad: Dictionary = save.snapshot(loaded)
	bad.clinic.patients.june = {"progress": 3.0}
	return "Unrestored clinic accepted prepaid patients" if save.valid(bad) else ""
