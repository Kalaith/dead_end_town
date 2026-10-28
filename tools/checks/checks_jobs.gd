extends RefCounted
const Checks = preload("res://tools/checks/checks_restoration.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")


func check_one_off_construction_resumes_grower_through_save_and_cancel() -> String:
	var w: RefCounted = Checks.prepared()
	w.assign_survivor("mara", "garden")
	w.passages.north = Neighbourhood.initial(w.catalog).north
	w.player.pos = Vector2(600, 400)
	w.interact()
	w.assign_survivor("mara", "passage:north")
	w.survivors[0].pos = Vector2(600, 400)
	w.working = false
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.survivors[0].duty.return_task != "garden":
		return "Temporary job lost its configured return on reload."
	Neighbourhood.step(loaded, 6.0)
	if loaded.survivors[0].order != "Garden" or loaded.survivors[0].duty.temporary or loaded.survivors[0].duty.role != "garden":
		return "Finished passage did not restore the grower."
	loaded.passages.south = Neighbourhood.initial(loaded.catalog).south
	loaded.player.pos = Vector2(600, 760)
	loaded.interact()
	loaded.assign_survivor("mara", "passage:south")
	Neighbourhood.cancel(loaded, "passage:south")
	return "Cancelled passage erased regular duty" if loaded.survivors[0].order != "Garden" else ""


func check_tactical_follow_and_return_home_preserve_regular_work() -> String:
	var w: RefCounted = Checks.prepared()
	w.assign_survivor("mara", "garden")
	w.order("Follow")
	if w.survivors[0].order != "Follow" or w.survivors[0].duty.role != "garden":
		return "Following erased home work."
	w.order("Home")
	if w.survivors[0].order != "Garden":
		return "Returning home did not resume configured work."
	w.assign_survivor("mara", "home")
	Jobs.step(w, 1.0)
	return "Queue commandeered explicit home guard" if w.survivors[0].order not in ["Home", "Guard"] or w.survivors[0].duty.role != "home" else ""


func check_builder_uses_approved_priority_then_returns_for_next_project() -> String:
	var w: RefCounted = Checks.prepared()
	w.player.pos = Vector2(1080, 800)
	Restoration.approve(w, "workshop")
	WorkOrders.prioritise(w, "restore:workshop", true)
	var stock: int = w.materials
	w.assign_survivor("mara", "builder")
	Jobs.step(w, 0.05)
	if w.survivors[0].order != "Workshop" or w.survivors[0].duty.role != "builder":
		return "Builder ignored an approved priority project."
	w.survivors[0].pos = Vector2(1080, 800)
	w.working = false
	Restoration.step(w, "workshop", 16.0)
	Jobs.step(w, 0.05)
	if w.survivors[0].order != "Garden" or w.survivors[0].duty.role != "builder":
		return "Builder did not retain its duty and select the next approved project."
	return "Queue billed an already paid project" if WorkOrders.current(w, "restore:garden").inputs.materials != 8 or stock != w.materials else ""


func check_reassignment_releases_executor_immediately_and_clear_time_survives_reload() -> String:
	var w: RefCounted = Checks.prepared()
	w.working = false
	w.assign_survivor("mara", "garden")
	w.survivors[0].pos = Vector2(1080, 350)
	Restoration.step(w, "garden", 1.0)
	w.assign_survivor("mara", "hold")
	if WorkOrders.current(w, "restore:garden").executor != "":
		return "Reassigned person kept a paid executor lease."
	w.assign_survivor("mara", "garden")
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = Vector2(1200, 350)
	Jobs.step(w, 0.05)
	w.zombies[0].hp = 0.0
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.survivors[0].duty.clear_left != 5.0:
		return "Saved danger-clear timer was lost."
	Jobs.step(loaded, 4.0)
	Restoration.step(loaded, "garden", 1.0)
	if loaded.garden_progress != 1.0:
		return "Work restarted before five clear seconds."
	Jobs.step(loaded, 1.0)
	Restoration.step(loaded, "garden", 1.0)
	return "Clear worker did not resume without another debit" if loaded.garden_progress != 2.0 else ""


func check_schema_eighteen_assignments_migrate_and_invalid_duties_are_rejected() -> String:
	var w: RefCounted = Checks.prepared()
	w.assign_survivor("mara", "garden")
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 18
	for a: Dictionary in old.survivors:
		a.erase("duty")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.materials != w.materials or loaded.survivors[0].duty.role != "garden":
		return "Old assigned grower did not retain its work and supplies."
	for entry: Array in [["role", "wizard"], ["retry", -1], ["clear_left", 6], ["temporary", "yes"]]:
		var bad: Dictionary = save.snapshot(loaded)
		bad.survivors[0].duty[entry[0]] = entry[1]
		if save.valid(bad):
			return "Accepted malformed duty " + str(entry[0])
	return ""
