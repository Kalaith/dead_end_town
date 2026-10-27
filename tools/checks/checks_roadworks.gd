extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")


func _street() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("library")
	return w


func _advance(w: RefCounted, seconds: float) -> void:
	for i: int in range(int(ceil(seconds / 0.05))):
		w.step(0.05)


func _build(w: RefCounted, index: int) -> void:
	w.player.pos = w.routes.point(w.catalog.barricades[index].site)
	w.interact()
	w.working = true
	_advance(w, float(w.balance.barricade_seconds) + 0.1)
	w.working = false


func check_barricades_require_both_facing_properties_and_charge_once() -> String:
	var w := World.new(Catalog.read())
	w.player.pos = Vector2(592, 580)
	w.interact()
	if w.roadworks.home_east.phase != "empty" or w.materials != 18:
		return "Built a defence before claiming both sides."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("library")
	w.materials = 7
	w.interact()
	if w.roadworks.home_east.phase != "empty":
		return "Built an unaffordable defence."
	w.materials = 20
	_build(w, 1)
	return "Construction did not charge exactly once" if w.roadworks.home_east.phase != "ready" or w.materials != 12 else ""


func check_road_collision_build_occupancy_and_dismantle_salvage() -> String:
	var w: RefCounted = _street()
	w.player.pos = Vector2(640, 580)
	w.interact()
	w.working = true
	_advance(w, 8.1)
	if w.roadworks.home_east.phase != "building" or not w.routes.walkable(Vector2(640, 580)):
		return "Construction trapped an actor or gained collision too soon."
	w.player.pos = Vector2(592, 580)
	w.step(0.05)
	w.working = false
	if w.roadworks.home_east.phase != "ready" or w.routes.walkable(Vector2(640, 580)):
		return "Completed defence did not block the road."
	w.move_input = Vector2.RIGHT
	_advance(w, 1.0)
	w.move_input = Vector2.ZERO
	if w.player.pos.x >= 621:
		return "Player walked through a barricade."
	var before: int = w.materials
	w.interact()
	w.working = true
	_advance(w, 2.0)
	w.working = false
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.routes.walkable(Vector2(640, 580)):
		return "Reload lost a half-dismantled barrier's collision."
	loaded.working = true
	_advance(loaded, 2.1)
	loaded.working = false
	if loaded.materials != before + 6 or not loaded.routes.walkable(Vector2(640, 580)):
		return "Dismantling failed to refund six materials and reopen the road."
	_advance(loaded, 1.0)
	return "Salvage duplicated" if loaded.materials != before + 6 else ""


func check_cancel_damage_and_repair_accounting_survive_reload() -> String:
	var w: RefCounted = _street()
	var stock: int = w.materials
	w.player.pos = Vector2(592, 580)
	w.interact()
	w.interact()
	if w.materials != stock:
		return "Unworked blueprint did not refund its commitment."
	w.interact()
	w.working = true
	_advance(w, 4.0)
	w.working = false
	w.interact()
	if w.materials != stock - 1 or w.roadworks.home_east.phase != "empty":
		return "Part-built cancellation did not recover its remaining materials once."
	_build(w, 1)
	w.roadworks.home_east.hp = 90.0
	if Roadworks.salvage(w, w.roadworks.home_east) != 3:
		return "Damage did not reduce salvage."
	w.working = true
	w.step(0.05)
	w.working = false
	stock = w.materials
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	loaded.working = true
	_advance(loaded, 4.0)
	loaded.working = false
	if loaded.materials != stock or float(loaded.roadworks.home_east.hp) != 180 or loaded.roadworks.home_east.repair_reserved:
		return "Interrupted repair charged twice or failed to finish."
	loaded.interact()
	loaded.interact()
	return "Cancelling dismantling paid salvage or lost collision" if loaded.materials != stock or not Roadworks.active(loaded.roadworks.home_east) else ""


func check_raiders_attack_road_barricades_from_both_directions_and_breach() -> String:
	for index: int in [0, 1]:
		var w: RefCounted = _street()
		_build(w, index)
		for a: Dictionary in w.survivors:
			a.hp = 0.0
		w.player.pos = Vector2(360, 350)
		var z: Dictionary = w.zombies[0]
		z.pos = Vector2(100 if index == 0 else 620, 580)
		z.hp = 60.0
		z.raid = true
		var id: String = w.catalog.barricades[index].id
		_press(w, z, Vector2.LEFT if index == 0 else Vector2.RIGHT, 4.0)
		if float(w.roadworks[id].hp) >= 180 or w.roadworks[id].phase != "ready":
			return "Raider did not attack the %s barricade." % id
		_press(w, z, Vector2.LEFT if index == 0 else Vector2.RIGHT, 35.0)
		if w.roadworks[id].phase != "empty" or not w.routes.walkable(w.routes.point(w.catalog.barricades[index].center)):
			return "Destroyed %s failed to reopen collision." % id
	return ""


func check_mara_reaches_road_job_handoffs_and_defenders_strike_over_it() -> String:
	var w: RefCounted = _street()
	w.properties.home.open = true
	w.rebuild_routes()
	w.player.pos = Vector2(592, 580)
	w.interact()
	w.working = true
	_advance(w, 2.0)
	w.working = false
	w.assign_mara()
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	_advance(loaded, 12.0)
	if loaded.roadworks.home_east.phase != "ready" or loaded.survivors[0].job != "":
		return "Saved road job failed to route and finish with Mara."
	var a: Dictionary = loaded.survivors[0]
	a.pos = Vector2(600, 580)
	a.order = "Hold"
	a.anchor = a.pos
	var z: Dictionary = loaded.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(670, 580)
	loaded.step(0.05)
	return "Defender cannot strike over the low road barricade" if float(z.hp) >= 60 else ""


func check_road_guards_route_hold_posts_survive_reload_and_leave_removed_line() -> String:
	var w: RefCounted = _street()
	w.properties.home.open = true
	w.rebuild_routes()
	_build(w, 0)
	_build(w, 1)
	w.post_road_guard()
	w.player.pos = Vector2(128, 580)
	w.post_road_guard()
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Road guards were not valid save state."
	loaded.player.pos = Vector2(360, 350)
	_advance(loaded, 8.0)
	for a: Dictionary in loaded.survivors:
		if a.order != "Roadguard" or a.pos.distance_to(a.anchor) > 5:
			return "Guard failed to physically reach a road post: %s" % a
	var z: Dictionary = loaded.zombies[0]
	z.pos = Vector2(670, 580)
	z.hp = 60.0
	z.raid = true
	_press(loaded, z, Vector2.LEFT, 8.0)
	if float(z.hp) > 0 or not Roadworks.active(loaded.roadworks.home_east):
		return "Road guard failed to hold an actual approach."
	loaded.player.pos = Vector2(592, 580)
	loaded.interact()
	loaded.working = true
	_advance(loaded, 4.1)
	var retained: int = 0
	for a: Dictionary in loaded.survivors:
		if a.order == "Roadguard":
			retained += 1
	return "Removing one line did not release only its guard" if retained != 1 else ""


func check_expansion_moves_defensive_line_and_legacy_saves_migrate() -> String:
	var w: RefCounted = _street()
	w.claim("garden")
	w.claim("garage")
	_build(w, 0)
	_build(w, 1)
	_build(w, 3)
	w.player.pos = Vector2(592, 580)
	w.interact()
	w.working = true
	_advance(w, 4.1)
	w.working = false
	if not w.routes.walkable(Vector2(640, 580)) or w.routes.walkable(Vector2(1360, 580)):
		return "Moving the line did not reopen the inner road and retain the new outer defence."
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 2
	old.mara_site = "garden"
	old.erase("roadworks")
	old.erase("road_job")
	var data: Dictionary = save.store.upgraded(old)
	if not save.valid(data) or data.materials != w.materials or data.workshop != w.workshop:
		return "Schema-2 migration changed existing progress."
	var bad: Dictionary = save.snapshot(w)
	bad.roadworks.home_west.hp = -1
	if save.valid(bad):
		return "Negative defence health accepted."
	bad = save.snapshot(w)
	bad.roadworks.home_west.phase = "empty"
	return "Inconsistent defence phase accepted" if save.valid(bad) else ""


func _press(w: RefCounted, z: Dictionary, direction: Vector2, seconds: float) -> void:
	# Stage repeated random-direction contact to verify damage and breach collision.
	for i: int in range(int(ceil(seconds / 0.05))):
		z.roam_angle = direction.angle()
		z.roam_left = 1.0
		w.step(0.05)
