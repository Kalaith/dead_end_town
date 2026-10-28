extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")
const EquipmentChecks = preload("res://tools/checks/checks_equipment.gd")


func check_meals_consume_for_the_current_roster_without_hunger_damage() -> String:
	var w := World.new(Catalog.read())
	w.food = 8
	w.provisions.clock = 59.99
	Provisions.step(w, 0.05)
	if w.food != 6:
		return "Starting team meal did not consume two food."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("library")
	w.food = 8
	w.provisions.clock = 59.99
	Provisions.step(w, 0.05)
	if w.food != 5:
		return "Rescued person did not join the shared meal."
	w.food = 0
	w.provisions.clock = 59.99
	var hp: float = w.player.hp
	Provisions.step(w, 0.05)
	for i: int in range(100):
		Provisions.step(w, 1)
	return "Hunger caused damage, debt or repeated meal accumulation" if not w.provisions.hungry or w.player.hp != hp or w.food != 0 or w.provisions.clock != 0 else ""


func check_shortage_slows_labour_and_a_connected_harvest_restores_work() -> String:
	var w: RefCounted = EquipmentChecks.prepared()
	w.workshop.armour_done = false
	w.workshop.armour_progress = 0.0
	w.provisions.hungry = true
	w.food = 0
	w.working = true
	w.step(0.05)
	if not is_equal_approx(w.workshop.armour_progress, 0.05 * float(w.balance.shortage_work_rate)):
		return "Hungry workshop did not use the reduced work rate."
	w.garden_started = true
	w.garden_done = true
	w.garden_progress = float(w.balance.work_seconds)
	w.player.pos = Vector2(1080, 350)
	w.harvest = float(w.balance.food_seconds) - 0.01
	w.step(0.05)
	if w.food != 2 or w.provisions.harvested != 2:
		return "Connected tended garden did not deliver recorded food."
	w.harvest = float(w.balance.food_seconds) - 0.01
	w.step(0.05)
	w.step(0.05)
	return "Enough garden food failed to feed the team and restore work" if w.provisions.hungry or w.food != 1 or Provisions.work_rate(w) != 1.0 else ""


func check_recovery_costs_food_once_and_refuses_shortage_or_danger() -> String:
	var w := World.new(Catalog.read())
	w.player.pos = Vector2(360, 350)
	w.player.hp = 30.0
	w.survivors[0].hp = 0.0
	w.food = 1
	w.interact()
	if w.player.hp != 30 or w.survivors[0].hp != 0 or w.food != 1:
		return "Recovery without food changed health or supplies."
	w.food = 6
	w.alert = "THREATENED"
	w.interact()
	if w.food != 6:
		return "Dangerous recovery spent food."
	w.alert = "SAFE"
	w.interact()
	if w.food != 4 or w.player.hp != 100 or w.survivors[0].hp != 100:
		return "Paid recovery did not restore the team once."
	w.interact()
	return "Resting a healthy team spent extra food" if w.food != 4 else ""


func check_food_caches_are_unique_and_food_clock_reloads_without_offline_drain() -> String:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	var before: int = w.food
	w.claim("garden")
	if w.food != before + int(w.definition("garden").food_cache):
		return "First search did not recover its food cache."
	w.properties.garden.claimed = false
	before = w.food
	w.claim("garden")
	if w.food != before:
		return "Reclaiming duplicated food."
	w.provisions.clock = 59.99
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.food != w.food or not is_equal_approx(loaded.provisions.clock, 59.99):
		return "Food clock or stock changed merely by loading."
	Provisions.step(w, 0.05)
	Provisions.step(loaded, 0.05)
	return "Reload skipped or repeated a due meal" if w.food != loaded.food or w.provisions != loaded.provisions else ""


func check_provisions_migrate_and_reject_invalid_clocks() -> String:
	var w := World.new(Catalog.read())
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 9
	old.erase("provisions")
	var upgraded: Dictionary = save.migrate(old)
	if upgraded.is_empty() or upgraded.food != old.food or upgraded.provisions.clock != 0 or upgraded.provisions.hungry:
		return "Migration consumed food or immediately penalised an existing run."
	for mutation: Dictionary in [{"clock": -1}, {"clock": 60}, {"hungry": true, "clock": 1}, {"harvested": 0.5}, {"warned": "bad"}]:
		var raw: Dictionary = save.snapshot(w)
		raw.provisions.merge(mutation, true)
		if save.valid(raw):
			return "Invalid provisions accepted: " + str(mutation)
	return ""
