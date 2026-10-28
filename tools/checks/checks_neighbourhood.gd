extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")


func _street() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		w.claim(id)
	w.pressure.next = 65.0
	return w


static func integrate(w: RefCounted) -> void:
	# Explicit authored completed defences for unrelated production fixtures.
	for d: Dictionary in w.catalog.passages:
		w.passages[d.id] = {"started": true, "progress": float(w.balance.passage_seconds), "done": true, "open": true, "hp": float(w.balance.gate_health), "repair_reserved": false}
	for p: Dictionary in w.properties.values():
		p.open = true
	for d: Dictionary in w.catalog.barricades:
		w.roadworks[d.id] = {"phase": "ready", "progress": 0.0, "hp": float(w.balance.barricade_health), "repair_reserved": false}
	w.rebuild_routes()


func _advance(w: RefCounted, seconds: float) -> void:
	for i: int in range(ceili(seconds / 0.05)):
		w.step(0.05)


func check_passage_cost_handoff_cancellation_and_reload() -> String:
	var w: RefCounted = _street()
	w.player.pos = Vector2(600, 400)
	var before: int = w.materials
	w.interact()
	if not w.passages.north.started or w.materials != before - int(w.balance.passage_cost):
		return "Passage approval did not reserve exactly one material bundle."
	if w.routes.walkable(Vector2(640, 400)):
		return "Blueprint removed the existing fence."
	w.working = true
	_advance(w, 2)
	w.working = false
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or not is_equal_approx(loaded.passages.north.progress, 2.0):
		return "Passage progress failed to reload."
	loaded.survivors[0].pos = Vector2(600, 400)
	if not loaded.assign_survivor("mara", "passage:north"):
		return "Cannot hand the passage to a named worker."
	_advance(loaded, 4.2)
	if not loaded.passages.north.done or loaded.materials != before - int(w.balance.passage_cost):
		return "Worker did not complete saved construction once."
	if loaded.safe_connected("garden") or loaded.routes.walkable(Vector2(720, 400)):
		return "Completed closed gate was passable or productive."
	loaded.interact()
	if not loaded.safe_connected("garden") or not loaded.routes.walkable(Vector2(720, 400)):
		return "Opening the built passage failed to connect the yards."
	loaded.player.pos = Vector2(600, 760)
	loaded.interact()
	loaded.working = true
	_advance(loaded, 3)
	loaded.working = false
	loaded.assign_survivor("mara", "passage:south")
	loaded.interact()
	if loaded.passages.south.started or loaded.survivors[0].order == "Passage":
		return "Cancelling left a stale passage assignment."
	return "Cancellation duplicated materials" if loaded.materials > before - int(w.balance.passage_cost) else ""


func check_passage_routes_people_and_blocks_alley_flanks() -> String:
	var w: RefCounted = _street()
	integrate(w)
	w.properties.home.open = false
	w.properties.garden.open = false
	w.rebuild_routes()
	w.survivors[0].pos = Vector2(580, 400)
	w.player.pos = Vector2(1050, 400)
	w.assign_survivor("mara", "follow")
	_advance(w, 6)
	if w.survivors[0].pos.x < 900:
		return "Survivor failed to physically use the direct yard passage."
	if w.routes.walkable(Vector2(720, 352)) or w.routes.walkable(Vector2(720, 448)):
		return "Alley can enter through the passage's fence rails."
	w.player.pos = Vector2(720, 400)
	w.move_input = Vector2.RIGHT
	_advance(w, 1)
	return "Player cannot traverse cut yard fences" if w.player.pos.x < 850 else ""


func check_crossings_require_real_boundary_access_and_clear_corridor() -> String:
	var w: RefCounted = _street()
	if w.safe_connected("library"):
		return "Ownership alone secured the crossing."
	for id: String in ["home_west", "home_east"]:
		w.roadworks[id] = {"phase": "ready", "progress": 0.0, "hp": 180.0, "repair_reserved": false}
	w.properties.home.open = true
	w.rebuild_routes()
	if not w.safe_connected("library"):
		return "Clear defended crossing was not operational."
	w.properties.library.open = false
	w.rebuild_routes()
	if w.safe_connected("library"):
		return "Closed yard gate did not block connection."
	w.properties.library.open = true
	var z: Dictionary = w.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(400, 580)
	if w.safe_connected("library"):
		return "Hostile street corridor remained operational."
	z.hp = 0.0
	w.roadworks.home_east.phase = "empty"
	w.roadworks.home_east.hp = 0.0
	return "Open boundary remained a safe crossing" if w.safe_connected("library") else ""


func check_alternate_safe_route_survives_lost_corner_and_restores_production() -> String:
	var w: RefCounted = _street()
	integrate(w)
	w.properties.garden.claimed = false
	if not w.safe_connected("garage") or w.safe_connected("garden"):
		return "Lost corner did not preserve only the valid alternate route."
	w.passages.south.open = false
	w.rebuild_routes()
	if w.safe_connected("garage"):
		return "Disconnected garage stayed productive."
	w.properties.garden.claimed = true
	w.garden_started = true
	w.garden_done = true
	w.garden_progress = float(w.balance.work_seconds)
	w.player.pos = Vector2(1080, 350)
	w.working = true
	w.passages.north.open = false
	w.properties.garage.claimed = false
	w.rebuild_routes()
	var clock: float = w.harvest
	_advance(w, 2)
	if w.harvest != clock:
		return "Disconnected garden produced into the home stockpile."
	w.passages.north.open = true
	w.rebuild_routes()
	_advance(w, 2)
	return "Reconnected garden failed to resume" if w.harvest <= clock else ""


func check_passage_occupancy_loss_breach_and_repair() -> String:
	var w: RefCounted = _street()
	integrate(w)
	w.player.pos = Vector2(600, 400)
	w.survivors[0].pos = Vector2(720, 400)
	w.interact()
	if not w.passages.north.open:
		return "Closed a passage gate through a living actor."
	w.survivors[0].pos = Vector2(360, 440)
	w.interact()
	w.passages.north.hp = 1.0
	var z: Dictionary = w.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(700, 400)
	if not Neighbourhood.bump(w, z, Vector2(712, 400)) or w.passages.north.hp != 0:
		return "Random collision could not breach the passage gate."
	if not w.routes.walkable(Vector2(720, 400)):
		return "Breached gate retained collision."
	z.hp = 0.0
	w.working = true
	_advance(w, 0.5)
	var stock: int = w.materials
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Partly repaired passage rejected on reload."
	loaded.working = true
	_advance(loaded, 8)
	if loaded.materials != stock or not loaded.passages.north.open or loaded.passages.north.hp != float(w.balance.gate_health):
		return "Gate repair failed, charged twice or closed through its repairer."
	loaded.properties.garden.claimed = false
	return "Passage ignored lost endpoint" if loaded.safe_connected("garden") else ""


func check_neighbourhood_migration_and_malformed_state_refusal() -> String:
	var w: RefCounted = _street()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 7
	old.erase("passages")
	var upgraded: Dictionary = save.migrate(old)
	if not save.valid(upgraded) or upgraded.materials != old.materials or upgraded.survivors != old.survivors or upgraded.passages.north.started:
		return "Schema seven migration changed progress or granted construction."
	for mutation: Dictionary in [{"done": true}, {"open": true}, {"progress": -1}, {"hp": "bad"}, {"repair_reserved": true}]:
		var raw: Dictionary = save.snapshot(w)
		raw.passages.north.merge(mutation, true)
		if save.valid(raw):
			return "Malformed passage accepted: " + str(mutation)
	var data: Dictionary = Catalog.read()
	data.passages[0].rails[0][2] = -1
	return "Malformed passage content accepted" if Catalog.problems(data).is_empty() else ""
