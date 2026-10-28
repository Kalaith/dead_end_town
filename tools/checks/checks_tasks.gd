extends RefCounted
const NeighbourhoodChecks = preload("res://tools/checks/checks_neighbourhood.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")


func _street() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		w.claim(id)
	NeighbourhoodChecks.integrate(w)
	for id: String in ["home_west", "home_east"]:
		w.roadworks[id] = {"phase": "empty", "progress": 0.0, "hp": 0.0, "repair_reserved": false}
	w.properties.home.open = true
	w.rebuild_routes()
	w.player.pos = Vector2(1080, 350)
	w.interact()
	w.player.pos = Vector2(1080, 800)
	w.interact()
	w.player.pos = Vector2(360, 445)
	return w


func _advance(w: RefCounted, seconds: float) -> void:
	for i: int in range(int(ceil(seconds / 0.05))):
		w.step(0.05)


func check_two_survivors_physically_work_different_jobs_while_player_guards() -> String:
	var w: RefCounted = _street()
	var stock: int = w.materials
	if not w.assign_survivor("mara", "garden") or not w.assign_survivor("paige", "garage"):
		return "Could not give both people independent assignments."
	_advance(w, 28.0)
	if not w.garden_done or not w.workshop.done:
		return "Independent garden and workshop work did not finish."
	if w.survivors[0].job != "garden" or w.survivors[1].job != "garage":
		return "Completing one task cleared another survivor's assignment."
	if w.survivors[0].pos.distance_to(Vector2(1080, 350)) >= 40 or w.survivors[1].pos.distance_to(Vector2(1080, 800)) >= 40:
		return "A survivor worked remotely instead of reaching their own site."
	if w.materials != stock or w.player.pos != Vector2(360, 445):
		return "Assignment spent more materials or moved the guarding player."
	# Keep the longer campaign harvest isolated from the separate raid acceptance cases.
	w.pressure.next = w.elapsed + 90.0
	w.food = 4
	w.growing.garden = false
	var food: int = w.food
	_advance(w, float(w.balance.food_seconds) + 0.1)
	if w.food <= food:
		return "Assigned gardener did not produce food after building the beds."
	w.assign_survivor("paige", "follow")
	return "Redirecting Paige changed Mara's gardening" if w.survivors[0].order != "Garden" else ""


func check_same_site_does_not_double_labour_and_untended_food_pauses() -> String:
	var w: RefCounted = _street()
	for a: Dictionary in w.survivors:
		w.assign_survivor(a.id, "garden")
		a.pos = Vector2(1080, 350)
	w.player.pos = Vector2(1080, 350)
	w.working = true
	_advance(w, 3.0)
	if not is_equal_approx(w.garden_progress, 3.0):
		return "Multiple assigned people and player multiplied one site's work rate."
	_advance(w, 10.0)
	w.working = false
	w.assign_survivor("mara", "home")
	w.assign_survivor("paige", "home")
	var food: int = w.food
	var clock: float = w.harvest
	_advance(w, 20.0)
	return "Untended garden kept producing" if w.food != food or not is_equal_approx(w.harvest, clock) else ""


func check_independent_orders_survive_save_and_invalid_jobs_are_rejected() -> String:
	var w: RefCounted = _street()
	w.assign_survivor("mara", "garden")
	w.assign_survivor("paige", "garage")
	_advance(w, 6.0)
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.survivors[0].job != "garden" or loaded.survivors[1].job != "garage":
		return "Reload lost the independent job targets."
	_advance(loaded, 24.0)
	if not loaded.garden_done or not loaded.workshop.done:
		return "Reloaded workers failed to resume physical work."
	var bad: Dictionary = save.snapshot(w)
	bad.survivors[1].job = "missing"
	if save.valid(bad):
		return "Unknown assignment target accepted."
	bad = save.snapshot(w)
	bad.survivors[1].erase("job")
	return "Missing assignment target accepted" if save.valid(bad) else ""


func check_paige_can_build_a_road_while_mara_gardens() -> String:
	var w: RefCounted = _street()
	w.player.pos = Vector2(592, 580)
	w.interact()
	if not w.assign_survivor("mara", "garden") or not w.assign_survivor("paige", "work:home_east"):
		return "Paige could not take road work."
	_advance(w, 27.0)
	if w.roadworks.home_east.phase != "ready" or not w.garden_done:
		return "Paige's road job interfered with Mara's garden job."
	return "Road completion cleared unrelated garden order" if w.survivors[0].order != "Garden" or w.survivors[1].job != "" else ""


func check_assignments_refuse_unapproved_work_and_downed_people() -> String:
	var w := World.new(Catalog.read())
	var stock: int = w.materials
	if w.assign_survivor("mara", "garden") or w.assign_survivor("mara", "garage") or w.assign_survivor("paige", "home"):
		return "Assigned unapproved work or an unrecruited survivor."
	w.survivors[0].hp = 0.0
	if w.assign_survivor("mara", "follow"):
		return "Assigned a downed survivor."
	return "Rejected assignment changed supplies" if w.materials != stock else ""


func check_threats_pause_one_job_and_both_people_can_swap_roles() -> String:
	var w: RefCounted = _street()
	w.assign_survivor("mara", "garden")
	w.assign_survivor("paige", "garage")
	w.survivors[0].pos = Vector2(1080, 350)
	w.survivors[1].pos = Vector2(1080, 800)
	var z: Dictionary = w.zombies[0]
	z.pos = Vector2(1240, 800)
	z.hp = 60.0
	_advance(w, 2.0)
	if float(w.workshop.progress) != 0 or w.garden_progress <= 0:
		return "Workshop danger stalled the other job or allowed unsafe work."
	z.hp = 0.0
	# Five clear seconds plus the real journey back from shelter.
	_advance(w, 16.0)
	if float(w.workshop.progress) <= 0 or w.survivors[1].order != "Workshop":
		return "Workshop role failed to resume after sheltering."
	var stock: int = w.materials
	w.assign_survivor("mara", "garage")
	w.assign_survivor("paige", "garden")
	_advance(w, 24.0)
	if not w.garden_done or not w.workshop.done or w.survivors[0].job != "garage" or w.survivors[1].job != "garden":
		return "Workers could not swap roles and resume each other's progress."
	return "Role handoff charged again" if w.materials != stock else ""


func check_schema_three_moves_legacy_work_targets_to_each_actor() -> String:
	var w: RefCounted = _street()
	w.player.pos = Vector2(592, 580)
	w.interact()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 3
	old.mara_site = "garage"
	old.road_job = "home_east"
	old.survivors[0].order = "Build"
	old.survivors[1].order = "Follow"
	for a: Dictionary in [old.player] + old.survivors + old.zombies:
		a.erase("job")
	var data: Dictionary = save.migrate(old)
	if data.is_empty() or data.survivors[0].job != "garage" or data.materials != old.materials or data.survivors[1].order != "Follow":
		return "Legacy workshop assignment did not migrate safely."
	old.survivors[0].order = "Roadwork"
	data = save.migrate(old)
	if data.is_empty() or data.survivors[0].job != "home_east":
		return "Legacy road assignment did not migrate safely."
	old.road_job = "missing"
	return "Bad legacy work destination accepted" if not save.migrate(old).is_empty() else ""
