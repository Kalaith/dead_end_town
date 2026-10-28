extends RefCounted
const ClinicChecks = preload("res://tools/checks/checks_clinic.gd")
const Greenhouse = preload("res://scripts/sim/greenhouse.gd")
const FoodGrowing = preload("res://scripts/sim/food_growing.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Discoveries = preload("res://scripts/sim/discoveries.gd")
const Roster = preload("res://scripts/sim/roster.gd")


func check_greenhouse_search_requires_local_clearance_and_rescues_once() -> String:
	var w := World.new(Catalog.read())
	var stock: int = w.materials
	if Discoveries.search(w, "greenhouse"):
		return "Remote greenhouse search succeeded."
	w.player.pos = Vector2(3960, 350)
	if w.context().contains("Oliver") or Discoveries.search(w, "greenhouse"):
		return "Occupied greenhouse revealed or granted its rescue."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.interact()
	if w.materials != stock + 16 or w.food != 16 or w.rescue_intro != "oliver" or w.properties.greenhouse.claimed:
		return "Search did not grant the separate finite cache and Oliver."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.rescue_intro != "oliver" or Roster.dismiss(loaded, "home"):
		return "Pending Oliver introduction failed reload or allowed an unsafe return."
	if not Roster.dismiss(loaded, "hold") or Roster.person(loaded, "oliver").order != "Hold" or Discoveries.search(loaded, "greenhouse"):
		return "Oliver choice or once-only rescue failed."
	loaded.food = loaded.survivors.size() + 1
	loaded.provisions.clock = float(loaded.balance.meal_seconds) - 0.05
	loaded.step(0.05)
	return "Oliver did not count for the next meal" if loaded.food != 0 else ""


func check_schema_twenty_nine_adds_only_greenhouse_residents_without_rewards() -> String:
	var w := World.new(Catalog.read())
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 29
	var prior: Array = []
	for z: Dictionary in old.zombies:
		if z.home != "greenhouse":
			prior.append(z)
	old.zombies = prior.duplicate(true)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.properties.greenhouse.looted or loaded.materials != w.materials or loaded.food != w.food or loaded.roam_rng.state != w.roam_rng.state or not Roster.person(loaded, "oliver").is_empty():
		return "Old save lost progress or gained a greenhouse reward."
	var result: Dictionary = save.snapshot(loaded)
	if result.zombies.slice(0, prior.size()) != prior or result.zombies.size() != prior.size() + 3:
		return "Greenhouse migration changed existing residents."
	return ""


static func prepared(restore: bool = false) -> RefCounted:
	var w: RefCounted = ClinicChecks.connected_clinic()
	w.player.pos = Vector2(3960, 350)
	Discoveries.search(w, "greenhouse")
	Roster.dismiss(w, "hold")
	w.claim("greenhouse")
	w.player.pos = Vector2(3480, 400)
	w.interact()
	w.working = true
	Neighbourhood.step(w, float(w.balance.passage_seconds))
	w.working = false
	w.interact()
	w.player.pos = Vector2(3960, 350)
	if restore:
		Greenhouse.approve(w)
		w.working = true
		Greenhouse.step(w, float(w.balance.greenhouse_seconds))
		w.working = false
	w.food = 8
	return w


func check_greenhouse_restoration_is_paid_cancellable_and_one_shared_site_rate() -> String:
	var w: RefCounted = prepared()
	var stock: int = w.materials
	if not w.safe_connected("greenhouse") or not Greenhouse.approve(w) or Greenhouse.approve(w) or w.materials != stock - 16:
		return "Greenhouse restoration route or one-time payment failed."
	w.assign_survivor("oliver", "greenhouse")
	w.working = true
	Greenhouse.step(w, 6.0)
	if w.greenhouse.progress != 6.0:
		return "Grower plus player multiplied restoration labour."
	w.properties.greenhouse.claimed = false
	Greenhouse.step(w, 50.0)
	if w.greenhouse.progress != 6.0:
		return "Lost greenhouse advanced restoration."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.greenhouse.progress != 6.0:
		return "Paid greenhouse work failed JSON reload."
	stock = loaded.materials
	if not Greenhouse.cancel(loaded, "restore:greenhouse") or Greenhouse.cancel(loaded, "restore:greenhouse") or loaded.materials != stock + 15 or Roster.person(loaded, "oliver").order != "Idle":
		return "Greenhouse cancellation failed its once-only exact refund/duty release."
	return ""


func check_greenhouse_harvest_needs_present_labour_and_pauses_for_loss_danger_and_route() -> String:
	var w: RefCounted = prepared(true)
	var stock: int = w.food
	FoodGrowing.step(w, 5.0)
	if w.greenhouse.harvest != 0:
		return "Untended greenhouse produced food."
	w.working = true
	w.assign_survivor("oliver", "greenhouse")
	FoodGrowing.step(w, 20.0)
	if w.greenhouse.harvest != 20.0 or w.food != stock:
		return "Player plus Oliver doubled food work."
	w.properties.greenhouse.claimed = false
	FoodGrowing.step(w, 10.0)
	w.claim("greenhouse")
	w.passages.clinic_greenhouse.open = false
	w.rebuild_routes()
	FoodGrowing.step(w, 10.0)
	w.passages.clinic_greenhouse.open = true
	w.rebuild_routes()
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = Vector2(4030, 400)
	FoodGrowing.step(w, 10.0)
	if w.greenhouse.harvest != 20.0 or w.food != stock:
		return "Lost, disconnected or threatened greenhouse grew food."
	w.zombies[0].hp = 0.0
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Interrupted harvest did not reload."
	loaded.working = true
	FoodGrowing.step(loaded, 40.0)
	if loaded.food != stock + 4 or loaded.greenhouse.harvest != 0 or loaded.provisions.harvested != 4:
		return "Resumed harvest did not deliver exactly four Food once."
	FoodGrowing.step(loaded, 0.0)
	return "Repeated completed harvest paid again" if loaded.food != stock + 4 else ""


func check_oliver_walks_the_protected_route_and_grows_without_the_player() -> String:
	var w: RefCounted = prepared(true)
	var oliver: Dictionary = Roster.person(w, "oliver")
	oliver.pos = Vector2(3240, 350)
	w.player.pos = Vector2(360, 350)
	w.assign_survivor("oliver", "greenhouse")
	FoodGrowing.step(w, 10.0)
	if w.greenhouse.harvest != 0:
		return "Remote Oliver supplied labour."
	for i: int in range(200):
		w.step(0.05)
	if oliver.pos.distance_to(Vector2(3960, 350)) >= 40 or w.greenhouse.harvest <= 0:
		return "Oliver did not walk through the protected passage to work."
	oliver.hp = 0.0
	var before: float = w.greenhouse.harvest
	FoodGrowing.step(w, 10.0)
	return "Downed grower supplied labour" if w.greenhouse.harvest != before else ""


func check_food_target_waits_with_hysteresis_and_preserves_partial_harvests() -> String:
	var w: RefCounted = prepared(true)
	w.working = true
	w.greenhouse.harvest = 30.0
	w.food = FoodGrowing.target(w)
	FoodGrowing.step(w, 10.0)
	if not w.growing.greenhouse or w.greenhouse.harvest != 30.0:
		return "Food target failed to pause partial work."
	w.food -= w.survivors.size() + 1
	FoodGrowing.step(w, 10.0)
	if w.greenhouse.harvest != 30.0:
		return "One meal at the resume boundary defeated hysteresis."
	w.food -= 1
	FoodGrowing.step(w, 10.0)
	if w.growing.greenhouse or w.greenhouse.harvest != 40.0:
		return "Food target failed to resume below the meal buffer."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	return "Food waiting state did not survive reload" if loaded == null or loaded.growing != w.growing or loaded.greenhouse.harvest != 40.0 else ""


func check_schema_thirty_preserves_clock_fractions_and_rejects_invalid_greenhouse_work() -> String:
	var w: RefCounted = prepared()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 30
	old.erase("greenhouse")
	old.erase("growing")
	old.harvest = 10.0
	old.provisions.clock = 30.0
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.greenhouse.started or loaded.harvest != 22.5 or loaded.provisions.clock != 60.0 or loaded.food != w.food or loaded.materials != w.materials or loaded.survivors.size() != w.survivors.size():
		return "Meal/garden retune lost clock fractions, stock or Oliver."
	var bad: Dictionary = save.snapshot(loaded)
	bad.greenhouse.done = true
	if save.valid(bad):
		return "Free completed greenhouse passed validation."
	bad = save.snapshot(loaded)
	bad.greenhouse.harvest = 60.0
	return "Completed uncredited harvest passed validation" if save.valid(bad) else ""


func check_temporary_greenhouse_construction_resumes_previous_duty() -> String:
	var w: RefCounted = prepared()
	Greenhouse.approve(w)
	w.assign_survivor("oliver", "hold")
	if not Jobs.assign_order(w, "restore:greenhouse", "oliver"):
		return "Work board could not assign Oliver to restoration."
	Greenhouse.step(w, 24.0)
	var a: Dictionary = Roster.person(w, "oliver")
	return "Temporary restoration did not return to Hold" if not w.greenhouse.done or a.order != "Hold" or a.duty.temporary else ""


func check_six_people_have_a_fifteen_minute_food_loop_with_interruptions_and_medical_costs() -> String:
	var w: RefCounted = prepared(true)
	w.claim("residence")
	if w.survivors.size() != 5:
		return "Food acceptance fixture does not contain six people."
	w.garden_started = true
	w.garden_done = true
	w.garden_progress = float(w.balance.work_seconds)
	w.assign_survivor("mara", "garden")
	w.assign_survivor("oliver", "greenhouse")
	Roster.person(w, "mara").pos = Vector2(1080, 350)
	w.player.pos = Vector2(360, 350)
	w.food = 16
	for second: int in range(900):
		# 30% downtime at both sites; no production is granted during interruptions.
		var work: float = 1.0 if second % 10 < 7 else 0.0
		FoodGrowing.step(w, work)
		if second in [240, 480, 720]:
			# Two recovery intervals and one medicine batch use the same two-Food input.
			w.food -= 2
		Provisions.step(w, 1.0)
		if w.provisions.hungry or w.food < 0:
			return "Six-person food loop fell into shortage under 30% interruptions."
	return "Food loop never harvested" if w.provisions.harvested < 32 else ""


func check_player_walks_into_the_greenhouse_clears_residents_and_searches_the_shed() -> String:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		if z.home != "greenhouse":
			z.hp = 0.0
	w.player.pos = Vector2(3960, 580)
	for i: int in range(600):
		var target: Dictionary = {}
		var distance: float = INF
		for z: Dictionary in w.zombies:
			if z.home == "greenhouse" and float(z.hp) > 0 and w.player.pos.distance_to(z.pos) < distance:
				target = z
				distance = w.player.pos.distance_to(z.pos)
		if target.is_empty():
			break
		w.aim = w.player.pos.direction_to(target.pos)
		var next: Vector2 = w.routes.waypoint(w.player.pos, target.pos)
		w.move_input = w.player.pos.direction_to(next) if distance > 58 else Vector2.ZERO
		w.attack()
		w.step(0.05)
		if w.defeat_pending:
			return "Greenhouse approach defeated the command-driven basic-bat player."
	if w.remaining("greenhouse") > 0:
		return "Player failed to physically clear greenhouse residents."
	var site := Vector2(3960, 350)
	for i: int in range(160):
		if w.player.pos.distance_to(site) < 25:
			break
		w.move_input = w.player.pos.direction_to(w.routes.waypoint(w.player.pos, site))
		w.step(0.05)
	w.move_input = Vector2.ZERO
	w.interact()
	return "Cleared greenhouse did not allow the local shed rescue" if w.rescue_intro != "oliver" or not w.properties.greenhouse.looted else ""
