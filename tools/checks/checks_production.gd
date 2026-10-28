extends RefCounted
const Checks = preload("res://tools/checks/checks_firearms.gd")
const Tasks = preload("res://scripts/sim/tasks.gd")
const Production = preload("res://scripts/sim/production.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Catalog = preload("res://scripts/core/catalog.gd")


static func staffed() -> RefCounted:
	var w: RefCounted = Checks.prepared()
	w.assign_survivor("ellis", "ammo")
	Tasks.person(w, "ellis").pos = Vector2(1800, 800)
	return w


func check_one_batch_stops_and_target_repeats_only_until_met() -> String:
	var w: RefCounted = staffed()
	Production.configure(w, "once", 24, 6)
	var stock: int = w.materials
	Firearms.step(w, 15.0)
	Firearms.step(w, 15.0)
	if int(w.firearms.bullets) != 12 or w.materials != stock - 2 or w.production.mode != "stopped":
		return "One batch did not stop after its single output."
	Production.configure(w, "repeat", 18, 6)
	Firearms.step(w, 15.0)
	Firearms.step(w, 15.0)
	if int(w.firearms.bullets) != 18 or w.materials != stock - 4 or w.production.reason != "Target met":
		return "Repeat target overproduced or spent beyond its target."
	w.firearms.bullets = 12
	Firearms.step(w, 15.0)
	return "Repeat did not resume after ammo use" if int(w.firearms.bullets) != 18 else ""


func check_lower_target_or_stop_finishes_prepaid_batch_without_new_spend() -> String:
	for mode: String in ["stopped", "repeat"]:
		var w: RefCounted = staffed()
		Firearms.step(w, 5.0)
		var stock: int = w.materials
		Production.configure(w, mode, 0, 999)
		Firearms.step(w, 10.0)
		Firearms.step(w, 15.0)
		if int(w.firearms.bullets) != 12 or w.materials != stock or Firearms.reserved(w):
			return "Changed target erased prepaid work or started another batch."
	return ""


func check_material_reserve_pauses_until_stock_or_policy_changes() -> String:
	var w: RefCounted = staffed()
	w.materials = 7
	Firearms.step(w, 5.0)
	if Firearms.reserved(w) or w.materials != 7 or w.production.reason != "Materials reserved":
		return "Automatic work spent the protected reserve."
	Production.configure(w, "repeat", 24, 5)
	if w.materials != 7:
		return "Changing policy spent materials while paused."
	Firearms.step(w, 5.0)
	if not Firearms.reserved(w) or w.materials != 5:
		return "Lower reserve did not permit a valid physical worker."
	Production.configure(w, "stopped", 24, 5)
	if not Production.cancel(w) or w.materials != 6 or Production.cancel(w):
		return "Cancellation failed exact once-only return."
	return ""


func check_unsafe_route_blocks_bullet_work_and_reclaim_resumes_same_batch() -> String:
	var w: RefCounted = staffed()
	Firearms.step(w, 4.0)
	var stock: int = w.materials
	w.passages.far_south.open = false
	Firearms.step(w, 20.0)
	if Firearms.progress(w) != 4 or w.production.reason != "Secure home route":
		return "Unsafe facility completed its output."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Blocked order/policy did not survive JSON reload."
	loaded.passages.far_south.open = true
	Firearms.step(loaded, 11.0)
	return "Route recovery lost or charged the batch again" if loaded.materials != stock or int(loaded.firearms.bullets) != 12 else ""


func check_undiscovered_bench_has_no_automatic_production_or_policy_leak() -> String:
	var w := World.new(Catalog.read())
	if w.production.mode != "stopped" or Production.configure(w, "repeat", 24, 6):
		return "Undiscovered recipe starts automatically."
	var ready: RefCounted = staffed()
	var save := SaveState.new(ready.catalog)
	var old: Dictionary = save.snapshot(ready)
	old.schema_version = 13
	old.erase("production")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.production.mode != "repeat" or int(loaded.production.target) != 24:
		return "Legacy worker did not migrate to bounded repeating production."
	for field: String in ["target", "material_reserve"]:
		var bad: Dictionary = save.snapshot(ready)
		bad.production[field] = 1.5
		if save.valid(bad):
			return "Fractional policy accepted."
	return ""
