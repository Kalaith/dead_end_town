extends RefCounted
const Tasks = preload("res://scripts/sim/tasks.gd")
const Checks = preload("res://tools/checks/checks_firearms.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const SaveState = preload("res://scripts/core/save_state.gd")


func check_partial_schema_twelve_batch_migrates_without_another_debit() -> String:
	var w: RefCounted = Checks.prepared()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 12
	old.erase("orders")
	old.firearms.progress = 7.0
	old.firearms.reserved = true
	old.materials -= 2
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or Firearms.progress(loaded) != 7.0:
		return "Prepaid legacy batch did not migrate."
	loaded.assign_survivor("ellis", "ammo")
	Tasks.person(loaded, "ellis").pos = Vector2(1800, 800)
	Firearms.step(loaded, 8.0)
	if loaded.materials != int(old.materials) or int(loaded.firearms.bullets) != 12:
		return "Migration charged again or lost output."
	return ""


func check_cancelled_batch_refunds_once_and_cannot_also_complete() -> String:
	var w: RefCounted = Checks.prepared()
	w.assign_survivor("ellis", "ammo")
	Tasks.person(w, "ellis").pos = Vector2(1800, 800)
	var stock: int = w.materials
	Firearms.step(w, 3.0)
	if int(WorkOrders.refund(Firearms.batch(w)).materials) != 1:
		return "Partial production refund is not proportional."
	if not WorkOrders.cancel(w, "munitions") or w.materials != stock - 1:
		return "Cancellation did not return the unconsumed share."
	if WorkOrders.cancel(w, "munitions") or WorkOrders.advance(w, "munitions", "ellis", 100.0):
		return "Terminal batch refunded or completed again."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	return "Cancelled order did not survive reload" if loaded == null or WorkOrders.cancel(loaded, "munitions") else ""


func check_destroyed_bundle_never_refunds_and_completion_never_repeats() -> String:
	var w: RefCounted = Checks.prepared()
	w.assign_survivor("ellis", "ammo")
	Tasks.person(w, "ellis").pos = Vector2(1800, 800)
	Firearms.step(w, 2.0)
	var stock: int = w.materials
	WorkOrders.cancel(w, "munitions", true)
	if w.materials != stock or WorkOrders.cancel(w, "munitions"):
		return "Destroyed order returned inputs."
	Firearms.step(w, 15.0)
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or WorkOrders.advance(loaded, "munitions", "ellis", 15.0) or int(loaded.firearms.bullets) != 12:
		return "Completed order repeated its output after load."
	return ""


func check_order_handoff_releases_lease_and_preserves_shared_progress() -> String:
	var w: RefCounted = Checks.prepared()
	w.assign_survivor("ellis", "ammo")
	Tasks.person(w, "ellis").pos = Vector2(1800, 800)
	Firearms.step(w, 3.0)
	var stock: int = w.materials
	w.assign_survivor("ellis", "hold")
	Firearms.step(w, 3.0)
	if Firearms.batch(w).executor != "" or Firearms.progress(w) != 3 or Firearms.batch(w).phase != "blocked":
		return "Departed worker kept a lease or progressed work."
	w.assign_survivor("mara", "ammo")
	w.survivors[0].pos = Vector2(1800, 800)
	Firearms.step(w, 12.0)
	return "Handoff lost the bundle" if w.materials != stock or int(w.firearms.bullets) != 12 else ""


func check_malformed_order_bundles_and_terminal_flags_are_rejected() -> String:
	var w: RefCounted = Checks.prepared()
	w.assign_survivor("ellis", "ammo")
	Tasks.person(w, "ellis").pos = Vector2(1800, 800)
	Firearms.step(w, 2.0)
	var save := SaveState.new(w.catalog)
	var raw: Dictionary = save.snapshot(w)
	for entry: Array in [["output_granted", true], ["salvage_paid", true], ["work_done", -1.0], ["work_required", 0.0], ["sequence", 100], ["inputs", {"materials": -2}], ["outputs", {"bullets": 600}]]:
		var bad: Dictionary = raw.duplicate(true)
		bad.orders.sites.munitions[entry[0]] = entry[1]
		if save.valid(bad):
			return "Accepted malformed order field: " + str(entry[0])
	return ""
