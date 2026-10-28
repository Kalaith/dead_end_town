extends RefCounted
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
