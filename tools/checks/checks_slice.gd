extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Objective = preload("res://scripts/sim/slice_objective.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const EquipmentChecks = preload("res://tools/checks/checks_equipment.gd")


static func ready() -> RefCounted:
	var w: RefCounted = EquipmentChecks.prepared()
	w.equipment.sword = "you"
	w.equipment.iron = "paige"
	w.equipment.shield = "paige"
	w.workshop.equipped = true
	w.garden_started = true
	w.garden_done = true
	w.garden_progress = float(w.balance.work_seconds)
	w.provisions.harvested = int(w.catalog.slice.harvest_food)
	w.player.pos = Vector2(360, 350)
	return w


func check_watch_requires_the_whole_loop_and_starts_only_at_home() -> String:
	var fresh := World.new(Catalog.read())
	if Objective.start(fresh) or fresh.slice_state.phase != "preparing" or Objective.next(fresh).contains("Paige"):
		return "Fresh street can finish or spoils an undiscovered survivor."
	var w: RefCounted = ready()
	w.player.pos = Vector2(1080, 800)
	if Objective.start(w):
		return "Watch started remotely."
	w.player.pos = Vector2(360, 350)
	w.provisions.harvested = 0
	if Objective.start(w):
		return "Cache food counted as garden production."
	w.provisions.harvested = 4
	w.equipment.iron = ""
	w.workshop.equipped = false
	if Objective.start(w):
		return "Watch started without deployed protection."
	w.equipment.iron = "paige"
	w.workshop.equipped = true
	w.food = 0
	if Objective.start(w):
		return "Watch started without a meal reserve."
	w.food = 8
	return "Complete prepared street could not begin" if not Objective.start(w) else ""


func check_watch_interrupts_on_loss_danger_shortage_and_downed_people() -> String:
	var w: RefCounted = ready()
	Objective.start(w)
	Objective.step(w, 20)
	w.properties.garden.claimed = false
	Objective.step(w, 0.05)
	if w.slice_state.held != 0 or w.slice_state.blocked.is_empty():
		return "Territory loss failed to restart the watch."
	w.properties.garden.claimed = true
	Objective.step(w, 10)
	w.passages.north.open = false
	w.passages.south.open = false
	Objective.step(w, 0.05)
	if w.slice_state.held != 0:
		return "Broken route did not restart the watch."
	w.passages.north.open = true
	w.passages.south.open = true
	Objective.step(w, 10)
	w.provisions.hungry = true
	Objective.step(w, 0.05)
	if w.slice_state.held != 0:
		return "Shortage did not restart the watch."
	w.provisions.hungry = false
	Objective.step(w, 10)
	w.survivors[0].hp = 0.0
	Objective.step(w, 0.05)
	return "Downed person did not restart the watch" if w.slice_state.held != 0 else ""


func check_watch_reload_finishes_once_and_continued_play_preserves_completion() -> String:
	var w: RefCounted = ready()
	Objective.start(w)
	Objective.step(w, 22.25)
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.slice_state.phase != "watch" or not is_equal_approx(loaded.slice_state.held, 22.25):
		return "Partial watch failed to reload."
	Objective.step(loaded, 37.75)
	if loaded.slice_state.phase != "complete" or not Objective.next(loaded).contains("Slice complete"):
		return "Watch failed to finish."
	var count: int = loaded.messages.size()
	loaded.properties.home.claimed = false
	Objective.step(loaded, 60)
	if loaded.slice_state.phase != "complete" or loaded.messages.size() != count:
		return "Continued play repeated or erased the earned finish."
	return "Completed street failed to reload after later loss" if save.restore(save.snapshot(loaded)) == null else ""


func check_complete_street_builds_from_authored_supplies_without_free_structures() -> String:
	var data: Dictionary = Catalog.read()
	# Isolate the economy/construction journey from raid balance; other scenarios exercise live arrivals.
	data.balance.approach_seconds = 1000
	var w := World.new(data)
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		if not w.claim(id):
			return "Cannot claim cleared fixture property."
		w.player.pos = w.routes.point(w.definition(id).site)
		if not w.salvage():
			return "Cannot recover authored timber."
		var stock: int = w.materials
		w.salvage()
		if w.materials != stock:
			return "Timber cache paid twice."
	w.player.pos = Vector2(360, 440)
	w.working = true
	_advance(w, 3)
	w.working = false
	w.interact()
	for d: Dictionary in w.catalog.barricades:
		w.player.pos = w.routes.point(d.site)
		w.interact()
		w.working = true
		_advance(w, 8.1)
		w.working = false
		if w.roadworks[d.id].phase != "ready":
			return "Authored supplies failed to build " + d.id
	for d: Dictionary in w.catalog.passages:
		if d.id not in ["north", "south"]:
			continue
		w.player.pos = w.routes.point(d.sites[0])
		w.interact()
		w.working = true
		_advance(w, 6.1)
		w.working = false
		w.interact()
		if not w.passages[d.id].done or not w.passages[d.id].open:
			return "Cannot build and open passage."
	w.player.pos = Vector2(1080, 350)
	w.interact()
	w.working = true
	_advance(w, 53)
	w.working = false
	if not w.garden_done or w.provisions.harvested < 4:
		return "Real garden labour failed to produce objective food."
	w.player.pos = Vector2(1080, 800)
	w.interact()
	w.working = true
	_advance(w, 16.1)
	w.working = false
	w.interact()
	w.working = true
	_advance(w, 18.1)
	w.working = false
	w.survivors[1].pos = Vector2(1110, 800)
	w.interact()
	if not Equipment.equip(w, "you", "weapon", "sword"):
		return "Real restored equipment failed to equip."
	if w.materials != 5:
		return "Full construction budget does not conserve the expected five spare materials: %d" % w.materials
	w.player.pos = Vector2(360, 350)
	if not Objective.start(w):
		return "Constructed street is not eligible: " + Objective.readiness(w)
	_advance(w, 60.1)
	return "Constructed, supplied street did not finish the watch" if w.slice_state.phase != "complete" else ""


func check_slice_migration_and_invalid_finish_states() -> String:
	var w: RefCounted = ready()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 10
	old.erase("slice_state")
	old.erase("timber")
	var upgraded: Dictionary = save.migrate(old)
	if upgraded.is_empty() or upgraded.materials != old.materials or upgraded.slice_state.phase != "preparing" or upgraded.timber.garden:
		return "Migration lost resources, completed the slice or consumed new timber."
	for mutation: Dictionary in [{"phase": "complete"}, {"phase": "watch", "held": -1}, {"held": 1}, {"phase": "unknown"}, {"blocked": true}]:
		var raw: Dictionary = save.snapshot(w)
		raw.slice_state.merge(mutation, true)
		if save.valid(raw):
			return "Invalid slice state accepted: " + str(mutation)
	return ""


func _advance(w: RefCounted, seconds: float) -> void:
	for i: int in range(ceili(seconds / 0.05)):
		w.step(0.05)
