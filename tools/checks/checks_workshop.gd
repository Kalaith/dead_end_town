extends RefCounted
const NeighbourhoodChecks = preload("res://tools/checks/checks_neighbourhood.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Combat = preload("res://scripts/sim/combat.gd")


func _street() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("library")
	w.claim("garage")
	w.claim("garden")
	NeighbourhoodChecks.integrate(w)
	w.player.pos = Vector2(1080, 800)
	return w


func _advance(w: RefCounted, seconds: float) -> void:
	for i: int in range(int(ceil(seconds / 0.05))):
		w.step(0.05)


func check_workshop_handoff_roundtrip_and_unique_equipment() -> String:
	var w: RefCounted = _street()
	var before: int = w.materials
	w.interact()
	w.interact()
	w.working = true
	_advance(w, 3.0)
	if w.materials != before - int(w.balance.workshop_cost):
		return "Workshop charged twice."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	loaded.survivors[0].pos = Vector2(1080, 800)
	loaded.assign_mara()
	loaded.working = true
	_advance(loaded, 4.0)
	if absf(float(loaded.workshop.progress) - 7.0) > 0.01:
		return "Two builders doubled workshop labour."
	loaded.working = false
	_advance(loaded, 10.0)
	if not loaded.workshop.done:
		return "Mara did not complete saved workshop work."
	loaded.interact()
	loaded.interact()
	loaded.assign_mara()
	_advance(loaded, float(loaded.balance.armour_seconds) + 0.2)
	if not loaded.workshop.armour_done or loaded.materials != before - int(w.balance.workshop_cost) - int(w.balance.armour_cost):
		return "Armour did not complete once at the expected cost."
	loaded.survivors[1].pos = Vector2(360, 800)
	loaded.interact()
	if loaded.workshop.equipped:
		return "Equipped Paige remotely."
	loaded.survivors[1].pos = Vector2(1110, 800)
	loaded.interact()
	loaded.interact()
	if not loaded.workshop.equipped:
		return "Could not equip Paige at the bench."
	var roundtrip: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(loaded))))
	return "Equipment lost on reload" if roundtrip == null or not roundtrip.workshop.equipped else ""


func check_workshop_pauses_for_danger_and_refuses_insufficient_materials() -> String:
	var w: RefCounted = _street()
	w.materials = 0
	w.interact()
	if w.workshop.started:
		return "Started unaffordable workshop."
	w.materials = 30
	w.interact()
	w.working = true
	var z: Dictionary = w.zombies[0]
	z.hp = float(w.catalog.zombies.types.shambler.health)
	z.pos = Vector2(1240, 790)
	_advance(w, 1.0)
	if float(w.workshop.progress) != 0:
		return "Unsafe workshop advanced."
	z.hp = 0.0
	_advance(w, 1.0)
	return "Safe work failed to resume without extra cost" if float(w.workshop.progress) <= 0 or w.materials != 20 else ""


func check_mara_routes_to_workshop_and_armour_work_survives_reload() -> String:
	var w: RefCounted = _street()
	w.properties.home.open = false
	w.passages.north.open = false
	w.rebuild_routes()
	w.interact()
	w.assign_mara()
	_advance(w, 1.0)
	if w.survivors[0].activity != "Route blocked - check gate" or float(w.workshop.progress) != 0:
		return "Closed home gate did not block workshop travel."
	w.properties.home.open = true
	w.rebuild_routes()
	for i: int in range(800):
		w.step(0.05)
		if w.workshop.done:
			break
	if not w.workshop.done or w.survivors[0].pos.distance_to(Vector2(1080, 800)) > 100:
		return "Mara failed to physically reach and restore the workshop: %s / %s" % [w.workshop, w.survivors[0]]
	w.interact()
	w.working = true
	_advance(w, 2.0)
	w.working = false
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or not is_equal_approx(float(loaded.workshop.armour_progress), 2.0):
		return "Interrupted armour labour lost on reload."
	var stock: int = loaded.materials
	loaded.assign_mara()
	_advance(loaded, 30.0)
	return "Saved armour failed to resume once" if not loaded.workshop.armour_done or loaded.materials != stock else ""


func check_schema_one_migrates_without_spending_or_changing_actors() -> String:
	var w: RefCounted = _street()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 1
	old.erase("workshop")
	old.erase("mara_site")
	var migrated: Dictionary = save.store.upgraded(JSON.parse_string(JSON.stringify(old)))
	if not save.valid(migrated) or migrated.materials != old.materials or migrated.survivors != old.survivors:
		return "Legacy migration changed progress or rejected valid data."
	var loaded: RefCounted = save.restore(migrated)
	if loaded.workshop.started or loaded.workshop.equipped:
		return "Migration granted unearned equipment."
	old.player.hp = -1
	return "Malformed legacy save accepted" if not save.migrate(old).is_empty() else ""


func check_invalid_workshop_states_are_rejected() -> String:
	var w: RefCounted = _street()
	var save := SaveState.new(w.catalog)
	for mutation: Dictionary in [{"equipped": true}, {"progress": -1}, {"armour_started": true}, {"done": true}, {"progress": "bad"}]:
		var data: Dictionary = save.snapshot(w)
		data.workshop.merge(mutation, true)
		if save.valid(data):
			return "Accepted impossible workshop state: %s" % mutation
	return ""


func check_armour_reduces_real_hits_and_shield_depends_on_facing() -> String:
	var w: RefCounted = _street()
	w.workshop.equipped = true
	w.equipment.iron = "paige"
	w.equipment.shield = "paige"
	var paige: Dictionary = w.survivors[1]
	paige.pos = Vector2(1080, 760)
	paige.order = "Hold"
	paige.anchor = paige.pos
	paige.facing = Vector2.RIGHT
	paige.cooldown = 10.0
	var front: float = Combat.incoming_damage(w, paige, paige.pos + Vector2.RIGHT * 20)
	var back: float = Combat.incoming_damage(w, paige, paige.pos + Vector2.LEFT * 20)
	if front <= 0 or front >= back or back >= float(w.catalog.zombies.types.shambler.damage):
		return "Armour and directional shield do not reduce damage correctly."
	var z: Dictionary = w.zombies[0]
	z.hp = float(w.catalog.zombies.types.shambler.health)
	z.pos = paige.pos + Vector2.RIGHT * 20
	var hp: float = float(paige.hp)
	w.step(0.05)
	if not is_equal_approx(float(paige.hp), hp - front):
		return "Real zombie hit did not apply equipment protection."
	z.hp = 0.0
	paige.anchor = paige.pos + Vector2.RIGHT * 100
	var start: Vector2 = paige.pos
	w.step(0.05)
	var expected: float = float(w.balance.survivor_speed) * float(w.balance.armour_speed_multiplier) * 0.05
	return "Heavy armour movement tradeoff missing" if absf(paige.pos.distance_to(start) - expected) > 0.01 else ""
