extends RefCounted
const ClinicChecks = preload("res://tools/checks/checks_clinic.gd")
const RecoveryChecks = preload("res://tools/checks/checks_recovery.gd")
const Medicine = preload("res://scripts/sim/medicine.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")


static func prepared() -> RefCounted:
	var w: RefCounted = ClinicChecks.connected_clinic()
	w.medicine = 0
	w.materials = 20
	w.food = 20
	w.working = true
	return w


func check_one_medicine_batch_commits_two_inputs_once_with_one_shared_worker_rate() -> String:
	var w: RefCounted = prepared()
	Medicine.configure(w, "once", 8, 6)
	w.assign_survivor("june", "clinic")
	Clinic.step(w, 15.0)
	if w.materials != 19 or w.food != 18 or w.medicine != 0 or WorkOrders.current(w, "clinic_medicine").work_done != 15:
		return "Medicine inputs were not atomic or two workers doubled progress."
	Clinic.step(w, 15.0)
	Clinic.step(w, 90.0)
	return "One batch repeated or granted the wrong output" if w.medicine != 2 or w.materials != 19 or w.food != 18 or w.medicine_production.mode != "stopped" else ""


func check_repeating_target_finishes_prepaid_batch_after_lowering_and_respects_both_reserves() -> String:
	var w: RefCounted = prepared()
	Medicine.configure(w, "repeat", 4, 6)
	Clinic.step(w, 30.0)
	Clinic.step(w, 10.0)
	Medicine.configure(w, "repeat", 0, 6)
	Clinic.step(w, 20.0)
	Clinic.step(w, 30.0)
	if w.medicine != 4 or w.materials != 18 or w.food != 16:
		return "Lower target erased paid medicine or started an extra batch."
	Medicine.configure(w, "once", 8, 6)
	w.materials = 6
	Clinic.step(w, 30.0)
	if Medicine.pending(w) or w.materials != 6 or w.food != 16:
		return "Medicine spent the material reserve."
	w.materials = 8
	w.food = Provisions.meal_cost(w) + 1
	Clinic.step(w, 30.0)
	if Medicine.pending(w) or w.materials != 8:
		return "Medicine spent the next meal or partially debited materials."
	w.food += 1
	Clinic.step(w, 30.0)
	return "Exact reserve-safe bundle failed" if w.medicine != 6 or w.materials != 7 or w.food != Provisions.meal_cost(w) else ""


func check_partial_medicine_loss_reload_and_civilian_worker_handoff_keep_the_bundle() -> String:
	var w: RefCounted = prepared()
	Medicine.configure(w, "once", 8, 6)
	Clinic.step(w, 15.0)
	w.properties.clinic.claimed = false
	Clinic.step(w, 100.0)
	if w.medicine != 0 or WorkOrders.current(w, "clinic_medicine").work_done != 15:
		return "Lost clinic produced medicine."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Two-input paid batch failed JSON reload."
	loaded.claim("clinic")
	loaded.assign_survivor("ellis", "clinic")
	var ellis: Dictionary = Equipment.person(loaded, "ellis")
	ellis.pos = Vector2(3240, 350)
	Clinic.step(loaded, 15.0)
	return "Worker handoff rebilled or lost medicine" if loaded.medicine != 2 or loaded.materials != 19 or loaded.food != 18 or ellis.order != "Clinic" else ""


func check_present_patient_takes_priority_without_losing_partial_medicine_work() -> String:
	var w: RefCounted = prepared()
	w.medicine = 3
	Medicine.configure(w, "once", 8, 6)
	Clinic.step(w, 15.0)
	var june: Dictionary = Equipment.person(w, "june")
	june.hp = 0.0
	Clinic.treat(w)
	Clinic.step(w, 10.0)
	if june.hp != 100 or w.medicine != 2 or WorkOrders.current(w, "clinic_medicine").work_done != 15:
		return "Production displaced a present paid patient or advanced twice."
	Clinic.step(w, 15.0)
	return "Medicine did not resume after treatment" if w.medicine != 4 or w.materials != 19 or w.food != 18 else ""


func check_cancelling_medicine_returns_each_input_exactly_once_and_rejects_bundle_drift() -> String:
	var w: RefCounted = prepared()
	Medicine.configure(w, "once", 8, 6)
	Clinic.step(w, 15.0)
	var save := SaveState.new(w.catalog)
	var bad: Dictionary = save.snapshot(w)
	bad.orders.sites.clinic_medicine.inputs.food = 20
	if save.valid(bad):
		return "Medicine input drift passed recipe validation."
	if not Medicine.cancel(w) or Medicine.cancel(w) or w.materials != 19 or w.food != 19 or w.medicine != 0:
		return "Partial medicine refunded an incorrect or repeatable amount."
	Clinic.step(w, 100.0)
	return "Cancelled medicine also granted output or failed validation" if w.medicine != 0 or not save.valid(save.snapshot(w)) else ""


func check_general_worker_walks_to_enabled_medicine_without_becoming_a_guard() -> String:
	var w: RefCounted = prepared()
	w.working = false
	w.pressure.next = 80.0
	var ellis: Dictionary = Equipment.person(w, "ellis")
	ellis.pos = Vector2(2520, 350)
	w.assign_survivor("ellis", "general")
	Medicine.configure(w, "once", 8, 6)
	for i: int in range(900):
		w.step(0.05)
	if w.medicine != 2 or w.materials != 19 or w.food != 18 or ellis.pos.distance_to(Vector2(3240, 350)) > 40 or ellis.duty.role != "general" or ellis.order in ["Guard", "Engage", "Home"]:
		return "General worker did not physically finish medicine and retain civilian duty."
	return ""


func check_schema_twenty_six_preserves_stocks_and_never_enables_a_recipe_on_discovery() -> String:
	var w: RefCounted = prepared()
	w.medicine = 11
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 26
	old.erase("medicine_production")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.medicine != 11 or loaded.materials != 20 or loaded.food != 20 or loaded.medicine_production.mode != "stopped":
		return "Medicine migration spent stock or enabled production."
	var unknown: RefCounted = RecoveryChecks.quiet()
	return "Undiscovered clinic accepted a production policy" if Medicine.configure(unknown, "once", 8, 6) else ""
