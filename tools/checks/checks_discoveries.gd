extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Discoveries = preload("res://scripts/sim/discoveries.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const EquipmentChecks = preload("res://tools/checks/checks_equipment.gd")


static func prepared() -> RefCounted:
	var w: RefCounted = EquipmentChecks.prepared()
	w.player.pos = Vector2(2520, 350)
	Discoveries.search(w, "hardware")
	w.player.pos = Vector2(1080, 800)
	return w


func check_search_requires_local_standing_clearance_and_never_leaks_a_reward() -> String:
	var w := World.new(Catalog.read())
	var stock: int = w.materials
	if Discoveries.search(w, "hardware"):
		return "Remote search succeeded."
	w.player.pos = Vector2(2520, 350)
	if w.context().contains("spear") or Discoveries.search(w, "hardware"):
		return "Occupied site revealed or paid its search reward."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.player.hp = 0.0
	w.interact()
	if Discoveries.search(w, "hardware") or w.properties.hardware.looted or w.materials != stock:
		return "Downed search spent or granted supplies."
	w.player.hp = 100.0
	return "Local clear search failed" if not Discoveries.search(w, "hardware") else ""


func check_search_before_claim_and_reclaim_pay_each_ledger_once_through_reload() -> String:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.player.pos = Vector2(2520, 350)
	var stock: int = w.materials
	var food: int = w.food
	w.interact()
	if not w.properties.hardware.looted or w.properties.hardware.claimed or w.properties.hardware.claimed_once or w.materials != stock + 32 or w.food != food + 2:
		return "Search was not a separate exact finite transaction."
	if w.claim("hardware") or Discoveries.search(w, "hardware"):
		return "Disconnected claim or duplicate search succeeded."
	w.claim("garden")
	w.claim("residence")
	stock = w.materials
	if not w.claim("hardware") or w.materials != stock + 6 or not w.properties.hardware.claimed_once:
		return "First connected claim did not pay six materials once."
	w.properties.hardware.claimed = false
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Searched/lost property failed reload."
	stock = loaded.materials
	if not loaded.claim("hardware") or loaded.materials != stock or Discoveries.search(loaded, "hardware"):
		return "Reclaim/reload repeated a finite payout."
	return ""


func check_schema_twenty_adds_only_new_hardware_residents_and_empty_spear() -> String:
	var w: RefCounted = EquipmentChecks.prepared()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 20
	old.equipment.erase("spear")
	for state: Dictionary in old.properties.values():
		state.erase("claimed_once")
	var prior: Array = []
	for z: Dictionary in old.zombies:
		if z.home != "hardware":
			prior.append(z)
	old.zombies = prior.duplicate(true)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.equipment.spear != "" or loaded.materials != w.materials or loaded.food != w.food or loaded.roam_rng.state != w.roam_rng.state:
		return "Schema twenty lost progress while adding hardware."
	var result: Dictionary = save.snapshot(loaded)
	if result.zombies.slice(0, prior.size()) != prior or result.zombies.size() != prior.size() + 3 or loaded.properties.hardware.looted:
		return "Migration changed old actors or granted a new reward."
	return ""


func check_spear_has_real_reach_one_target_and_two_hands() -> String:
	var w: RefCounted = prepared()
	Equipment.equip(w, "you", "shield", "shield")
	if Equipment.equip(w, "you", "weapon", "spear"):
		return "Spear accepted a simultaneous shield."
	Equipment.equip(w, "you", "shield", "none")
	if not Equipment.equip(w, "you", "weapon", "spear") or Equipment.equip(w, "mara", "weapon", "spear") or Equipment.equip(w, "you", "shield", "shield"):
		return "Two-hand/unique spear ownership failed."
	w.player.pos = Vector2(1500, 580)
	for i: int in range(2):
		w.zombies[i].hp = 100.0
		w.zombies[i].pos = w.player.pos + Vector2(100 + i * 12, 0)
	Combat.strike(w, w.player, Vector2.RIGHT)
	if w.zombies[0].hp != 62.0 or w.zombies[1].hp != 100.0 or w.player.cooldown != 0.8:
		return "Spear did not deliver one long-reach 38-damage hit."
	w.player.cooldown = 0.0
	w.player.pos = Vector2(750, 580)
	w.zombies[0].pos = Vector2(850, 580)
	w.zombies[1].hp = 0.0
	Combat.strike(w, w.player, Vector2.RIGHT)
	if w.zombies[0].hp != 24.0:
		return "Spear could not reach over the low road line."
	w.player.cooldown = 0.0
	w.player.pos = Vector2(1600, 250)
	w.zombies[0].pos = Vector2(1700, 250)
	Combat.strike(w, w.player, Vector2.RIGHT)
	if w.zombies[0].hp != 24.0:
		return "Spear hit through a tall building."
	var save := SaveState.new(w.catalog)
	var bad: Dictionary = save.snapshot(w)
	bad.equipment.shield = "you"
	return "Save accepted spear plus shield" if save.valid(bad) else ""
