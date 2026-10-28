extends RefCounted
const Restoration = preload("res://scripts/sim/restoration.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Territory = preload("res://scripts/sim/territory.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")


func check_occupation_requires_entry_and_living_defenders_prevent_loss() -> String:
	var w: RefCounted = _street()
	var z: Dictionary = w.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(1080, 510)
	Territory.step(w, 20)
	if not w.properties.garden.claimed:
		return "Zombie outside the property captured through a fence."
	z.pos = Vector2(1080, 400)
	w.player.pos = Vector2(1080, 350)
	Territory.step(w, 20)
	if not w.properties.garden.claimed:
		return "Player presence did not contest occupation."
	w.player.pos = Vector2(360, 350)
	w.survivors[0].hp = 100.0
	w.survivors[0].pos = Vector2(1080, 350)
	Territory.step(w, 20)
	if not w.properties.garden.claimed:
		return "Living survivor did not contest occupation."
	w.survivors[0].hp = 0.0
	Territory.step(w, 4)
	if not w.properties.garden.claimed or float(w.properties.garden.occupation) != 4:
		return "Warning window did not precede loss."
	z.hp = 0.0
	Territory.step(w, 1)
	if float(w.properties.garden.occupation) != 0:
		return "Clearing occupants failed to stop occupation."
	z.hp = 60.0
	Territory.step(w, 8)
	return "Downed survivor prevented loss" if w.properties.garden.claimed else ""


func check_loss_reload_reclaim_preserves_unique_rewards_and_work() -> String:
	var w: RefCounted = _street()
	w.player.pos = Vector2(1080, 350)
	Restoration.approve(w, "garden")
	w.working = true
	Restoration.step(w, "garden", 5.0)
	w.working = false
	w.player.pos = Vector2(360, 350)
	var supplies: int = w.materials
	var z: Dictionary = w.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(1080, 400)
	Territory.step(w, 4)
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or float(loaded.properties.garden.occupation) != 4:
		return "Occupation progress was lost on reload."
	Territory.step(loaded, 4)
	if loaded.properties.garden.claimed or loaded.connected("garden") or not save.valid(save.snapshot(loaded)):
		return "Lost state stayed operational or could not save."
	for enemy: Dictionary in loaded.zombies:
		enemy.hp = 0.0
	if not loaded.claim("garden") or loaded.materials != supplies or loaded.garden_progress != 5.0:
		return "Reclaim duplicated loot or reset committed work."
	z.hp = 0.0
	z = w.zombies[1]
	z.hp = 60.0
	z.pos = Vector2(360, 800)
	Territory.step(w, 8)
	z.hp = 0.0
	if not w.claim("library") or w.survivors.size() != 2 or w.materials != supplies:
		return "Reclaim duplicated rescue or supplies."
	return ""


func check_home_can_fall_and_be_recovered_without_stranding_save() -> String:
	var w: RefCounted = _street()
	w.player.pos = Vector2(1080, 350)
	var z: Dictionary = w.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(360, 400)
	Territory.step(w, 8)
	var save := SaveState.new(w.catalog)
	if w.properties.home.claimed or w.connected("garden") or save.restore(save.snapshot(w)) == null:
		return "Home loss or disconnected save is invalid."
	z.hp = 0.0
	w.player.pos = Vector2(360, 350)
	w.interact()
	return "Home cannot be reclaimed at its porch" if not w.properties.home.claimed else ""


func check_schema_five_migration_and_occupation_validation() -> String:
	var w: RefCounted = _street()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 5
	for p: Dictionary in old.properties.values():
		p.erase("occupation")
	var loaded: RefCounted = save.restore(old)
	if loaded == null or loaded.materials != w.materials or loaded.survivors.size() != 2:
		return "Schema-five migration lost existing progress."
	for bad: Variant in [-1, "bad", 8]:
		var raw: Dictionary = save.snapshot(w)
		raw.properties.garden.occupation = bad
		if save.valid(raw):
			return "Invalid occupation accepted."
	var data: Dictionary = Catalog.read()
	data.balance.erase("territory_fall_seconds")
	return "Missing occupation tuning accepted" if Catalog.problems(data).is_empty() else ""


func check_wanderer_contact_breaches_gate_then_can_occupy_property() -> String:
	var w: RefCounted = _street()
	w.properties.garden.open = false
	w.rebuild_routes()
	var z: Dictionary = w.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(1080, 500)
	# Contact headings are staged to check physical breach independently of luck.
	for i: int in range(750):
		z.roam_angle = -PI / 2 if z.pos.y > 400 else 0.0
		z.roam_left = 1.0
		w.step(0.05)
	if w.properties.garden.claimed or float(w.properties.garden.gate_hp) > 0:
		return "Repeated wanderer contact did not breach, enter and capture."
	return ""


func check_lost_raid_target_and_surviving_defences_remain_saveable() -> String:
	var w: RefCounted = _street()
	w.roadworks.garden_east.phase = "ready"
	w.roadworks.garden_east.hp = float(w.balance.barricade_health)
	w.rebuild_routes()
	w.elapsed = float(w.pressure.next)
	Pressure.step(w)
	for z: Dictionary in w.zombies:
		if z.raid:
			z.pos = Vector2(1080, 400)
			z.anchor = Vector2(1080, 480)
	Territory.step(w, 8)
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(save.snapshot(w))
	if loaded == null or loaded.properties.garden.claimed or float(loaded.roadworks.garden_east.hp) != float(w.balance.barricade_health):
		return "Loss discarded a surviving defence or invalidated raid targets."
	return ""


func _street() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		w.claim(id)
	for a: Dictionary in w.survivors:
		a.hp = 0.0
	w.pressure.next = 65.0
	return w
