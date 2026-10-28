extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Tasks = preload("res://scripts/sim/tasks.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")


static func prepared() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "garage", "munitions", "residence"]:
		w.claim(id)
	w.player.pos = Vector2(1800, 580)
	w.aim = Vector2.RIGHT
	w.food = 100
	return w


func check_new_properties_require_clearance_and_give_one_pistol_six_bullets() -> String:
	var w := World.new(Catalog.read())
	if w.catalog.properties.size() != 6 or w.survivors.size() != 1 or w.firearms.owned or w.shoot() or w.claim("residence"):
		return "Expansion is missing or reveals/grants an unearned rescue."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	if w.claim("munitions"):
		return "Disconnected ammunition workshop could be claimed."
	w.claim("garden")
	w.player.pos = Vector2(1800, 350)
	w.interact()
	if not w.firearms.owned or int(w.firearms.bullets) != 6 or Tasks.person(w, "ellis").is_empty():
		return "Porch interaction did not rescue Ellis and hand over exactly six bullets."
	w.firearms.bullets = 2
	w.properties.residence.claimed = false
	w.claim("residence")
	return "Reclaim duplicated survivor or ammunition" if w.survivors.size() != 2 or int(w.firearms.bullets) != 2 else ""


func check_pistol_hits_nearest_aimed_target_spends_misses_and_obeys_cooldown() -> String:
	var w: RefCounted = prepared()
	w.player.pos = Vector2(1500, 580)
	for i: int in range(3):
		w.zombies[i].hp = 100.0
		w.zombies[i].pos = Vector2(1650 + i * 100, 580 if i < 2 else 620)
	if not w.shoot() or float(w.zombies[0].hp) != 10 or float(w.zombies[1].hp) != 100 or int(w.firearms.bullets) != 5:
		return "Shot failed nearest-target damage or bullet accounting."
	if w.shoot() or int(w.firearms.bullets) != 5:
		return "Cooldown spent another bullet."
	w.player.cooldown = 0.0
	w.aim = Vector2.LEFT
	if not w.shoot() or int(w.firearms.bullets) != 4:
		return "Miss did not consume one bullet."
	w.player.cooldown = 0.0
	w.firearms.bullets = 0
	if w.shoot() or float(w.player.cooldown) != 0:
		return "Empty pistol fired or locked out melee."
	return ""


func check_pistol_range_and_closed_gate_block_damage() -> String:
	var w: RefCounted = prepared()
	w.player.pos = Vector2(1800, 580)
	w.aim = Vector2.UP
	var z: Dictionary = w.zombies[0]
	z.pos = Vector2(1800, 420)
	z.hp = 100.0
	w.properties.residence.open = false
	w.rebuild_routes()
	w.shoot()
	if float(z.hp) != 100 or float(w.shot.to.y) < 480:
		return "Bullet crossed a closed property gate."
	w.player.cooldown = 0.0
	w.properties.residence.open = true
	w.rebuild_routes()
	w.shoot()
	if float(z.hp) != 10:
		return "Open gate blocked a clear shot."
	z.hp = 100.0
	z.pos = Vector2(700, 580)
	w.player.cooldown = 0.0
	w.aim = Vector2.LEFT
	w.shoot()
	return "Shot exceeded authored range" if float(z.hp) != 100 else ""


func check_ellis_refuses_every_guard_path_and_never_attacks() -> String:
	var w: RefCounted = prepared()
	var a: Dictionary = Tasks.person(w, "ellis")
	for task: String in ["home", "engage", "guard:home_west"]:
		if w.assign_survivor("ellis", task):
			return "Ellis accepted a combat assignment."
	for order: String in ["Engage", "Home"]:
		w.order(order)
		if a.order in ["Home", "Guard", "Engage", "Roadguard"]:
			return "Whole-team command gave Ellis combat duty."
	a.pos = Vector2(1800, 800)
	a.anchor = a.pos
	a.order = "Hold"
	w.zombies[0].hp = 100.0
	w.zombies[0].pos = a.pos + Vector2(30, 0)
	Combat.strike(w, a, Vector2.RIGHT)
	Combat._survivor(w, a, 0.05)
	if float(w.zombies[0].hp) != 100 or not a.activity.begins_with("Sheltering"):
		return "Ellis fought or did not shelter from danger."
	w.roadworks.home_west = {"phase": "ready", "hp": 180.0, "progress": 0.0, "repair_reserved": false}
	w.properties.library.claimed = true
	w.player.pos = Vector2(128, 580)
	w.survivors[0].hp = 0.0
	w.post_road_guard()
	return "G assigned Ellis as guard" if a.order == "Roadguard" else ""


func check_assigned_worker_physically_arrives_and_crafts_one_shared_batch() -> String:
	var w: RefCounted = prepared()
	var a: Dictionary = Tasks.person(w, "ellis")
	a.pos = Vector2(1800, 580)
	if not w.assign_survivor("ellis", "ammo"):
		return "Cannot assign Ellis to unlocked bullet workshop."
	var stock: int = w.materials
	Firearms.step(w, 1.0)
	if w.materials != stock:
		return "Remote worker crafted without arriving."
	for i: int in range(90):
		w.step(0.05)
	if a.pos.distance_to(Vector2(1800, 800)) >= 40 or not w.firearms.reserved:
		return "Assigned worker did not physically enter the workshop and begin a batch."
	w.firearms.progress = 0.0
	w.assign_survivor("mara", "ammo")
	w.survivors[0].pos = a.pos
	Firearms.step(w, float(w.catalog.firearm.craft_seconds) - 0.1)
	if int(w.firearms.bullets) != 6:
		return "Two workers doubled production."
	Firearms.step(w, 0.1)
	return "Batch cost/yield wrong" if w.materials != stock - 2 or int(w.firearms.bullets) != 12 or w.firearms.reserved else ""


func check_crafting_interruptions_and_reload_preserve_reserved_materials() -> String:
	var w: RefCounted = prepared()
	var a: Dictionary = Tasks.person(w, "ellis")
	a.pos = Vector2(1800, 800)
	w.assign_survivor("ellis", "ammo")
	Firearms.step(w, 4.0)
	var stock: int = w.materials
	w.properties.munitions.claimed = false
	Firearms.step(w, 20.0)
	if float(w.firearms.progress) != 4 or w.materials != stock:
		return "Lost workshop consumed materials or continued crafting."
	w.properties.munitions.claimed = true
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or float(loaded.firearms.progress) != 4:
		return "Partial batch failed save roundtrip."
	loaded.zombies[0].hp = 100.0
	loaded.zombies[0].pos = Vector2(1800, 820)
	Firearms.step(loaded, 20.0)
	if float(loaded.firearms.progress) != 4:
		return "Crafting ignored nearby danger."
	loaded.zombies[0].hp = 0.0
	Firearms.step(loaded, 11.0)
	if loaded.materials != stock or int(loaded.firearms.bullets) != 12:
		return "Reload charged twice or lost the batch."
	loaded.materials = 0
	Firearms.step(loaded, 20.0)
	return "Crafted without materials" if loaded.firearms.reserved or int(loaded.firearms.bullets) != 12 else ""


func check_real_schema_eleven_expands_without_rewriting_old_progress() -> String:
	var w := World.new(Catalog.read())
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 11
	old.erase("firearms")
	for id: String in ["residence", "munitions"]:
		old.properties.erase(id)
	for id: String in ["far_north", "far_south"]:
		old.passages.erase(id)
	old.zombies = old.zombies.filter(func(z: Dictionary) -> bool: return z.home not in ["residence", "munitions"])
	var loaded: RefCounted = save.restore(old)
	if loaded == null or loaded.properties.size() != 6 or loaded.firearms.owned or loaded.materials != w.materials or loaded.zombies.size() != w.zombies.size():
		return "Old street did not expand safely."
	var raw: Dictionary = save.snapshot(loaded)
	for value: Variant in [-1, 1.5, "six"]:
		raw.firearms.bullets = value
		if save.valid(raw):
			return "Malformed bullet count accepted."
	var bad: Dictionary = w.catalog.duplicate(true)
	bad.firearm.material_cost = 1.5
	return "Malformed firearm content accepted" if Catalog.problems(bad).is_empty() else ""
