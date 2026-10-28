extends RefCounted
const ClinicChecks = preload("res://tools/checks/checks_clinic.gd")
const FieldMedicine = preload("res://scripts/sim/field_medicine.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const SaveState = preload("res://scripts/core/save_state.gd")


static func prepared(owner: String = "you") -> RefCounted:
	var w: RefCounted = ClinicChecks.connected_clinic()
	w.player.pos = Vector2(1080, 800)
	for a: Dictionary in w.survivors:
		a.pos = w.player.pos
		w.assign_survivor(a.id, "hold")
	Equipment.equip(w, owner, "shield", "field_bag")
	w.player.pos = Vector2(1000, 580)
	for a: Dictionary in w.survivors:
		a.pos = Vector2(1200, 580)
		w.assign_survivor(a.id, "hold")
	var mara: Dictionary = Equipment.person(w, "mara")
	mara.pos = Vector2(1030, 580)
	mara.hp = 30.0
	w.assign_survivor("mara", "hold")
	w.medicine = 12
	w.food = 30
	w.pressure.next = 90.0
	w.working = true
	return w


func check_held_work_spends_once_and_range_danger_reload_keep_paid_patient() -> String:
	var w: RefCounted = prepared()
	for i: int in range(30):
		w.step(0.05)
	var mara: Dictionary = Equipment.person(w, "mara")
	if w.medicine != 11 or mara.hp != 30 or not is_equal_approx(float(w.field_care.get("mara", -1)), 1.5):
		return "Held work failed one dose and partial progress."
	w.player.pos = Vector2(800, 580)
	FieldMedicine.step(w, 10)
	w.player.pos = Vector2(1000, 580)
	var z: Dictionary = w.zombies[0]
	z.hp = 80.0
	z.pos = Vector2(1060, 580)
	FieldMedicine.step(w, 10)
	z.hp = 0.0
	if not is_equal_approx(float(w.field_care.mara), 1.5) or w.medicine != 11:
		return "Range or danger lost progress or advanced the dose."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Partial field dose failed JSON reload."
	loaded.working = true
	FieldMedicine.step(loaded, 1.5)
	return "Reload rebilled or failed atomic healing" if loaded.medicine != 11 or Equipment.person(loaded, "mara").hp != 70 or not loaded.field_care.is_empty() else ""


func check_healthy_downed_and_work_sites_never_take_an_accidental_dose() -> String:
	var w: RefCounted = prepared()
	var mara: Dictionary = Equipment.person(w, "mara")
	mara.hp = 100.0
	FieldMedicine.step(w, 3)
	mara.hp = 0.0
	FieldMedicine.step(w, 3)
	if w.medicine != 12 or not w.field_care.is_empty():
		return "Healthy or downed target spent Medicine."
	mara.hp = 90.0
	w.player.pos = Vector2(1080, 660)
	mara.pos = Vector2(1080, 630)
	FieldMedicine.step(w, 3)
	if w.medicine != 12:
		return "Gate work instead spent Medicine."
	w.player.pos = Vector2(1000, 580)
	mara.pos = Vector2(1030, 580)
	FieldMedicine.step(w, 3)
	FieldMedicine.step(w, 3)
	return "Field healing overflowed or charged healthy person" if mara.hp != 100 or w.medicine != 11 else ""


func check_bag_is_unique_replaces_shield_and_disallows_two_handed_spear() -> String:
	var w: RefCounted = prepared()
	w.player.pos = Vector2(1080, 800)
	Equipment.person(w, "ellis").pos = w.player.pos
	if Equipment.equip(w, "ellis", "shield", "field_bag") or Equipment.equip(w, "you", "weapon", "spear") or Equipment.shielded(w, w.player):
		return "Bag duplicated, fitted spear or granted shield benefit."
	if not Equipment.equip(w, "you", "shield", "shield") or not w.equipment.field_bag.is_empty():
		return "Shield did not return bag to the bench."
	if not Equipment.equip(w, "you", "shield", "field_bag") or not w.equipment.shield.is_empty():
		return "Bag did not return shield to the bench."
	var save := SaveState.new(w.catalog)
	var bad: Dictionary = save.snapshot(w)
	bad.equipment.shield = "you"
	return "Conflicting off-hand items passed save validation" if save.valid(bad) else ""


func check_explicit_civilian_treatment_resumes_duty_after_tool_handoff_without_repayment() -> String:
	var w: RefCounted = prepared()
	FieldMedicine.step(w, 1.5)
	var ellis: Dictionary = Equipment.person(w, "ellis")
	w.player.pos = Vector2(1080, 800)
	ellis.pos = w.player.pos
	if not Equipment.equip(w, "you", "shield", "none") or not Equipment.equip(w, "ellis", "shield", "field_bag"):
		return "Bench handoff failed."
	w.player.pos = Vector2(1000, 580)
	ellis.pos = Vector2(1030, 600)
	w.assign_survivor("ellis", "general")
	w.working = false
	FieldMedicine.step(w, 20)
	if w.medicine != 11 or Equipment.person(w, "mara").hp != 30:
		return "Bag owner spent autonomously without explicit order."
	if not w.assign_survivor("ellis", "field:mara"):
		return "Civilian could not accept standing nearby patient."
	FieldMedicine.step(w, 0.5)
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Civilian temporary treatment failed JSON reload."
	FieldMedicine.step(loaded, 1.0)
	ellis = Equipment.person(loaded, "ellis")
	return "Handoff rebilled, healed wrong amount or lost return duty" if loaded.medicine != 11 or Equipment.person(loaded, "mara").hp != 70 or ellis.order != "Idle" or ellis.duty.role != "general" or ellis.duty.temporary else ""


func check_partial_self_care_uses_same_rules_and_discards_paid_capacity_after_other_healing() -> String:
	var w: RefCounted = prepared()
	Equipment.person(w, "mara").hp = 100.0
	w.player.hp = 50.0
	FieldMedicine.step(w, 1.0)
	if w.medicine != 11 or not w.field_care.has("you"):
		return "Standing self treatment failed."
	w.player.hp = 100.0
	FieldMedicine.step(w, 0.05)
	w.player.hp = 90.0
	FieldMedicine.step(w, 3.0)
	return "An old fully healed injury saved reusable paid capacity" if w.player.hp != 100 or w.medicine != 10 or not w.field_care.is_empty() else ""


func check_schema_twenty_eight_preserves_stocks_duties_and_rejects_bad_dose_progress() -> String:
	var w: RefCounted = prepared()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 28
	old.erase("field_care")
	old.equipment.erase("field_bag")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.medicine != 12 or loaded.food != 30 or not loaded.equipment.field_bag.is_empty() or not loaded.field_care.is_empty():
		return "Field bag migration lost stock or changed duty."
	for index: int in range(old.survivors.size()):
		if loaded.survivors[index].duty != old.survivors[index].duty or loaded.survivors[index].order != old.survivors[index].order:
			return "Field bag migration changed an existing duty or tactical order."
	for value: Variant in [-1, 3, "paid"]:
		var bad: Dictionary = save.snapshot(w)
		bad.field_care = {"mara": value}
		if save.valid(bad):
			return "Malformed or completed dose passed validation."
	var bad: Dictionary = save.snapshot(w)
	bad.field_care = {"absent": 1.0}
	return "Unknown patient passed validation" if save.valid(bad) else ""
