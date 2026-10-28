extends RefCounted
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
