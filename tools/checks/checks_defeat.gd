extends RefCounted
const World = preload("res://scripts/sim/world.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Defeat = preload("res://scripts/sim/defeat.gd")
const RecoveryChecks = preload("res://tools/checks/checks_recovery.gd")
const EquipmentChecks = preload("res://tools/checks/checks_equipment.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")


func check_lethal_tick_stops_before_recovery_work_and_due_arrivals_and_stays_saveable() -> String:
	var w: RefCounted = EquipmentChecks.prepared()
	w.player.pos = Vector2(1080, 350)
	Restoration.approve(w, "garden")
	w.working = true
	Restoration.step(w, "garden", 3.0)
	var orders: Dictionary = w.orders.duplicate(true)
	w.player.pos = Vector2(1500, 580)
	w.player.hp = 1.0
	for a: Dictionary in w.survivors:
		a.hp = 0.0
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = w.player.pos
	w.pressure.next = w.elapsed + 0.02
	var food: int = w.food
	var meal: float = w.provisions.clock
	w.step(0.05)
	if not w.defeat_pending or w.player.hp != 0 or w.player.pos != Vector2(1500, 580) or w.downs != 1 or w.pressure.wave != 0 or w.food != food or w.provisions.clock != meal or w.orders != orders:
		return "Lethal tick healed, moved, progressed paid work or ran the due raid."
	var save := SaveState.new(w.catalog)
	var snapshot: Dictionary = save.snapshot(w)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(snapshot)))
	if loaded == null or not loaded.defeat_pending:
		return "Pending lethal tick failed JSON reload, including its due arrival."
	snapshot = save.snapshot(loaded)
	for i: int in range(10):
		loaded.step(0.05)
	return "Defeat did not freeze all saved state" if save.snapshot(loaded) != snapshot else ""


func check_recovery_uses_nearest_clear_held_shelter_and_preserves_stocks_damage_and_gear() -> String:
	var w: RefCounted = EquipmentChecks.prepared()
	w.player.pos = Vector2(1300, 850)
	w.player.hp = 0.0
	w.survivors[0].hp = 0.0
	var standing: Dictionary = w.survivors[1].duplicate(true)
	Defeat.begin(w)
	var chosen: Dictionary = Defeat.destination(w)
	if chosen.emergency or chosen.point != Vector2(1080, 800):
		return "Recovery did not choose the nearest clear held porch."
	var stock: Array = [w.food, w.materials, w.medicine, w.firearms.duplicate(true)]
	var properties: Dictionary = w.properties.duplicate(true)
	var equipment: Dictionary = w.equipment.duplicate(true)
	var zombies: Array = w.zombies.duplicate(true)
	var elapsed: float = w.elapsed
	if not Defeat.recover(w) or w.player.hp != 50 or w.survivors[0].hp != 25 or w.survivors[1] != standing:
		return "Recovery changed a standing survivor or failed reduced health."
	if [w.food, w.materials, w.medicine, w.firearms] != stock or w.properties != properties or w.equipment != equipment or w.zombies != zombies or w.elapsed != elapsed:
		return "Recovery granted resources/repairs, altered enemies/gear or advanced time."
	if w.pressure.next < w.elapsed + 90 or Defeat.recover(w):
		return "Recovery repeated or failed its arrival preparation interval."
	var save := SaveState.new(w.catalog)
	return "Recovered shelter failed save validation" if not save.valid(save.snapshot(w)) else ""


func check_empty_stock_lost_home_and_all_downed_people_recover_at_west_without_deleting_zombies() -> String:
	var w: RefCounted = RecoveryChecks.quiet()
	w.food = 0
	w.materials = 0
	w.player.pos = Vector2(1080, 580)
	w.player.hp = 0.0
	for s: Dictionary in w.properties.values():
		s.claimed = false
	w.survivors[0].hp = 0.0
	for i: int in range(3):
		w.zombies[i].hp = 31.0 + i
		w.zombies[i].pos = Vector2(30 + i * 10, 550 + i * 25)
	var before: Array = w.zombies.duplicate(true)
	Defeat.begin(w)
	if not Defeat.destination(w).emergency or not Defeat.recover(w):
		return "No-stock/all-down/home-loss recovery was unavailable."
	if w.player.pos != Vector2(30, 580) or w.player.hp != 50 or w.survivors[0].hp != 25 or w.food != 0 or w.materials != 0 or w.properties.home.claimed:
		return "West foothold granted stock, ownership or the wrong health."
	if Defeat.positions(w, Vector2(30, 580)).size() < 9:
		return "West shelter cannot hold the full future roster."
	for i: int in range(w.zombies.size()):
		var z: Dictionary = w.zombies[i]
		if z.id != before[i].id or z.hp != before[i].hp:
			return "Emergency relocation deleted or changed a hostile."
		if i < 3 and (z.pos.distance_to(Vector2(30, 580)) < 240 or Defeat.controlled(w, z.pos) or not w.routes.walkable(z.pos)):
			return "Emergency hostile was not moved to valid uncontrolled road."
		if i >= 3 and z != before[i]:
			return "Recovery moved a distant actor or defeated corpse."
	return ""


func check_schema_twenty_four_preserves_people_and_stock_without_triggering_recovery() -> String:
	var w: RefCounted = RecoveryChecks.quiet()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 24
	old.erase("defeat_pending")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.defeat_pending or loaded.player != w.player or loaded.survivors != w.survivors or loaded.food != w.food or float(loaded.pressure.next) != float(w.pressure.next) or bool(loaded.pressure.warned) != bool(w.pressure.warned) or int(loaded.pressure.wave) != int(w.pressure.wave):
		return "Defeat migration drift: null=%s pending=%s player=%s survivors=%s food=%s pressure=%s" % [loaded == null, loaded.defeat_pending if loaded != null else true, loaded.player == w.player if loaded != null else false, loaded.survivors == w.survivors if loaded != null else false, loaded.food if loaded != null else -1, loaded.pressure if loaded != null else {}]
	var bad: Dictionary = save.snapshot(loaded)
	bad.defeat_pending = true
	return "Standing player accepted a pending defeat" if save.valid(bad) else ""
