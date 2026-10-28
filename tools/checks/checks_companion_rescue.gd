extends RefCounted
const Restoration = preload("res://scripts/sim/restoration.gd")
const Checks = preload("res://tools/checks/checks_equipment.gd")
const ClinicChecks = preload("res://tools/checks/checks_clinic.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const CompanionRescue = preload("res://scripts/sim/companion_rescue.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Defeat = preload("res://scripts/sim/defeat.gd")


static func prepared() -> RefCounted:
	var w: RefCounted = Checks.prepared()
	w.survivors[0].pos = Vector2(1080, 350)
	w.survivors[0].hp = 0.0
	w.player.pos = Vector2(1080, 350)
	Restoration.approve(w, "garden")
	w.player.pos = Vector2(1080, 800)
	w.assign_survivor("paige", "garden")
	return w


func check_companion_walks_lifts_and_carries_home_then_resumes_duty_through_reload() -> String:
	var w: RefCounted = prepared()
	if not w.assign_survivor("paige", "rescue:mara") or w.survivors[0].pos != Vector2(1080, 350):
		return "Rescue rejected safe routes or teleported its casualty on assignment."
	for i: int in range(145):
		w.step(0.05)
	if not w.rescue_jobs.has("paige") or w.rescue_jobs.paige.phase != "carry" or not Carrying.carried(w, "mara"):
		return "Companion failed the physical approach and two-second lift."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Carried companion rescue failed JSON reload."
	for i: int in range(400):
		loaded.step(0.05)
	if not loaded.rescue_jobs.is_empty() or loaded.survivors[0].hp != 0 or loaded.survivors[0].pos.distance_to(Vector2(360, 350)) >= 30 or Equipment.person(loaded, "paige").order != "Garden" or Equipment.person(loaded, "paige").duty.temporary:
		return "Drop-off healed/stranded the casualty or erased the return assignment."
	return ""


func check_closed_route_rejects_without_reassignment_and_route_loss_pauses_a_carried_patient() -> String:
	var w: RefCounted = prepared()
	w.passages.north.open = false
	w.properties.garden.open = false
	w.rebuild_routes()
	var before: Dictionary = Equipment.person(w, "paige").duplicate(true)
	if w.assign_survivor("paige", "rescue:mara") or Equipment.person(w, "paige") != before or not w.rescue_jobs.is_empty():
		return "Closed rescue route changed the original assignment."
	w.passages.north.open = true
	w.properties.garden.open = true
	w.rebuild_routes()
	w.assign_survivor("paige", "rescue:mara")
	for i: int in range(145):
		w.step(0.05)
	var point: Vector2 = Equipment.person(w, "paige").pos
	w.properties.home.claimed = false
	for i: int in range(80):
		w.step(0.05)
	if Equipment.person(w, "paige").pos != point or not Carrying.carried(w, "mara"):
		return "Lost home route continued movement or dropped the casualty."
	return ""


func check_individual_reassignment_drops_in_place_but_team_shortcuts_keep_the_rescue() -> String:
	var w: RefCounted = prepared()
	w.assign_survivor("paige", "rescue:mara")
	for i: int in range(145):
		w.step(0.05)
	w.order("Follow")
	if not w.rescue_jobs.has("paige") or Equipment.person(w, "paige").order != "Rescue":
		return "Team shortcut silently abandoned an emergency transport."
	var point: Vector2 = Equipment.person(w, "paige").pos
	if not w.assign_survivor("paige", "hold") or not w.rescue_jobs.is_empty() or w.survivors[0].pos != point or Carrying.carried(w, "mara"):
		return "Individual reassignment did not release one casualty in place."
	return ""


func check_downing_carrier_releases_patient_and_direct_combat_cannot_attack_while_loaded() -> String:
	var w: RefCounted = prepared()
	w.assign_survivor("paige", "rescue:mara")
	for i: int in range(145):
		w.step(0.05)
	var paige: Dictionary = Equipment.person(w, "paige")
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = paige.pos + Vector2(40, 0)
	Combat.strike(w, paige, Vector2.RIGHT)
	if w.zombies[0].hp != 60:
		return "Loaded companion attacked through a direct combat call."
	w.zombies[0].hp = 0.0
	paige.hp = 0.0
	var point: Vector2 = paige.pos
	w.step(0.05)
	if not w.rescue_jobs.is_empty() or w.survivors[0].pos != point or paige.order != "Idle":
		return "Downed carrier kept a ghost casualty or moved it elsewhere."
	var save := SaveState.new(w.catalog)
	return "Released downed-carrier state failed save validation" if not save.valid(save.snapshot(w)) else ""


func check_ellis_can_carry_without_combat_and_duplicate_ownership_is_rejected() -> String:
	var w: RefCounted = prepared()
	w.claim("residence")
	var ellis: Dictionary = Equipment.person(w, "ellis")
	ellis.pos = Vector2(1080, 800)
	w.assign_survivor("ellis", "general")
	if not w.assign_survivor("ellis", "rescue:mara") or w.assign_survivor("paige", "rescue:mara"):
		return "Civilian rescue failed or two carriers accepted one casualty."
	for i: int in range(400):
		w.step(0.05)
	if not w.rescue_jobs.is_empty() or ellis.order in ["Guard", "Home", "Engage"] or ellis.duty.role != "general" or w.survivors[0].pos.distance_to(Vector2(360, 350)) > 30:
		return "Ellis failed physical rescue or lost civilian/regular duty."
	return ""


func check_defeat_recovery_clears_transports_without_leaving_healthy_carried_patients() -> String:
	var w: RefCounted = prepared()
	w.assign_survivor("paige", "rescue:mara")
	for i: int in range(145):
		w.step(0.05)
	w.player.hp = 0.0
	w.step(0.05)
	Defeat.recover(w)
	var save := SaveState.new(w.catalog)
	return "Defeat left a healthy patient in a transport" if not w.rescue_jobs.is_empty() or w.survivors[0].hp != 25 or not save.valid(save.snapshot(w)) else ""


func check_schema_twenty_seven_preserves_duties_and_adds_no_rescue_or_transport() -> String:
	var w: RefCounted = prepared()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 27
	old.erase("rescue_jobs")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	return "Rescue migration changed duties or granted transport" if loaded == null or not loaded.rescue_jobs.is_empty() or loaded.survivors != w.survivors or loaded.materials != w.materials else ""


func check_rescuer_delivers_to_a_nearer_operational_clinic_without_spending_medicine() -> String:
	var w: RefCounted = ClinicChecks.connected_clinic()
	var june: Dictionary = Equipment.person(w, "june")
	june.hp = 0.0
	june.pos = Vector2(2520, 350)
	var ellis: Dictionary = Equipment.person(w, "ellis")
	ellis.pos = Vector2(2520, 450)
	w.assign_survivor("ellis", "general")
	var medicine: int = w.medicine
	if not w.assign_survivor("ellis", "rescue:june") or w.rescue_jobs.ellis.shelter != "clinic":
		return "Rescuer ignored the nearer operational treatment shelter."
	for i: int in range(400):
		w.step(0.05)
	return "Clinic drop failed, healed without treatment or spent medicine" if not w.rescue_jobs.is_empty() or june.pos.distance_to(Vector2(3240, 350)) >= 30 or june.hp != 0 or w.medicine != medicine else ""
