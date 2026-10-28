extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")


func check_catalog():
	return "Catalog rejected" if Catalog.read().is_empty() else ""


func check_player_moves_at_authored_speed_and_stops_at_gate():
	var w := World.new(Catalog.read())
	w.move_input = Vector2.RIGHT
	var start: Vector2 = w.player.pos
	for i: int in range(10):
		w.step(0.05)
	if absf(w.player.pos.x - start.x - 95) > 0.1:
		return "Movement speed differs from catalog."
	w.player.pos = Vector2(360, 440)
	w.move_input = Vector2.DOWN
	for i: int in range(15):
		w.step(0.05)
	return "Closed gate was passable" if w.player.pos.y > 459 else ""


func check_claim_requires_clearance_and_connection_and_rewards_once():
	var w := World.new(Catalog.read())
	if w.claim("garden"):
		return "Claimed an occupied yard."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	if w.claim("garage"):
		return "Claimed disconnected garage."
	var before: int = w.materials
	if not w.claim("garden") or not w.connected("garden"):
		return "Garden failed to connect."
	if w.claim("garden") or w.materials != before + int(w.balance.claim_materials):
		return "Claim reward duplicated."
	if not w.claim("library") or w.survivors.size() != 2:
		return "Paige rescue failed."
	w.claim("library")
	return "Paige duplicated" if w.survivors.size() != 2 else ""


func check_work_handoff_and_save_roundtrip_preserve_materials():
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("garden")
	w.player.pos = Vector2(1080, 350)
	w.interact()
	w.interact()
	if w.materials != int(w.balance.starting_materials) + int(w.balance.claim_materials) - int(w.balance.garden_cost):
		return "Garden charged more than once."
	w.working = true
	for i: int in range(60):
		w.step(0.05)
	w.working = false
	var save := SaveState.new(w.catalog)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(save.snapshot(w)))
	if not save.valid(raw):
		return "Valid snapshot rejected."
	var restored: RefCounted = save.restore(raw)
	restored.survivors[0].pos = Vector2(1080, 350)
	restored.assign_mara()
	for i: int in range(200):
		restored.step(0.05)
	if not restored.garden_done or restored.materials != int(w.balance.starting_materials) + int(w.balance.claim_materials) - int(w.balance.garden_cost):
		return "Saved work failed to finish exactly once after handoff."
	return ""


func check_home_guard_defends_local_contact_while_player_is_away() -> String:
	var w := World.new(Catalog.read())
	w.player.pos = Vector2(1080, 350)
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	var attacker: Dictionary = w.zombies[0]
	attacker.hp = 60.0
	attacker.pos = Vector2(360, 496)
	for i: int in range(40):
		w.step(0.05)
	if float(attacker.hp) > 0 or float(w.properties.home.gate_hp) <= 0 or float(w.survivors[0].hp) <= 0:
		return "Guard failed to hold a local contact while player was elsewhere."
	return ""


func check_invalid_saves_are_rejected():
	var w := World.new(Catalog.read())
	var save := SaveState.new(w.catalog)
	var data: Dictionary = save.snapshot(w)
	data.materials = -1
	if save.valid(data):
		return "Negative resources accepted."
	data = save.snapshot(w)
	data.survivors[0].pos = ["broken", 2]
	if save.valid(data):
		return "Malformed actor accepted."
	data = save.snapshot(w)
	data.properties.library.claimed = true
	return "Missing rescued survivor accepted" if save.valid(data) else ""


func check_same_commands_produce_same_snapshot():
	var data: Dictionary = Catalog.read()
	var a := World.new(data)
	var b := World.new(data)
	for i: int in range(1500):
		a.step(0.05)
		b.step(0.05)
	var save := SaveState.new(data)
	return "Fixed-step run differs" if save.snapshot(a) != save.snapshot(b) else ""


func check_builder_physically_reaches_garden_and_reports_closed_gate():
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("garden")
	w.player.pos = Vector2(1080, 350)
	w.interact()
	w.assign_mara()
	for i: int in range(60):
		w.step(0.05)
	if w.survivors[0].activity != "Route blocked - check gate":
		return "Closed home gate did not report blocked work: %s at %s" % [w.survivors[0].activity, w.survivors[0].pos]
	w.properties.home.open = true
	w.rebuild_routes()
	for i: int in range(600):
		w.step(0.05)
	return "Mara failed to physically reach and build the garden" if not w.garden_done else ""


func check_breach_opens_physical_route_and_repair_resumes_once():
	var w := World.new(Catalog.read())
	w.survivors[0].hp = 0.0
	w.player.pos = Vector2(1080, 350)
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	var attacker: Dictionary = w.zombies[0]
	attacker.hp = 60.0
	attacker.pos = Vector2(360, 496)
	for i: int in range(600):
		attacker.roam_angle = -PI / 2
		attacker.roam_left = 1.0
		w.step(0.05)
	if float(w.properties.home.gate_hp) > 0 or not w.routes.walkable(Vector2(360, 480)):
		return "Breach did not open collision."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("home")
	w.player.pos = Vector2(360, 440)
	w.working = true
	w.step(0.05)
	var stock: int = w.materials
	w.working = false
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	loaded.working = true
	for i: int in range(150):
		loaded.step(0.05)
	if loaded.materials != stock or float(loaded.properties.home.gate_hp) != float(loaded.balance.gate_health):
		return "Interrupted repair charged twice or failed to resume."
	return ""


func check_save_store_recovers_previous_valid_street():
	var w := World.new(Catalog.read())
	var path: String = "user://checks/street_roundtrip.json"
	for suffix: String in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	var save := SaveState.new(w.catalog, path)
	if not save.store.save_data(save.snapshot(w)):
		return save.store.last_error
	w.materials += 4
	if not save.store.save_data(save.snapshot(w)):
		return save.store.last_error
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("interrupted")
	file.close()
	var data: Dictionary = save.store.load_data()
	if not save.store.recovered or data.is_empty() or int(data.materials) != 18:
		return "Did not recover previous valid street."
	if not save.store.save_data(data) or not FileAccess.file_exists(path + ".corrupt"):
		return "Could not preserve damaged snapshot while saving recovered street."
	for suffix: String in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	return ""


func check_playable_garden_loop_through_movement_combat_and_interaction():
	var w := World.new(Catalog.read())
	w.order("Follow")
	if not _travel(w, Vector2(360, 430)):
		return "Cannot approach home gate."
	w.working = true
	for i: int in range(60):
		w.step(0.05)
	w.working = false
	w.interact()
	if not w.properties.home.open:
		return "Cannot open repaired gate."
	if not _travel(w, Vector2(1080, 350)):
		return "Cannot traverse continuous street into garden."
	# Seek scattered occupants with Mara assisting against nearby pursuers.
	for i: int in range(2400):
		var nearest: float = INF
		var target: Vector2 = w.player.pos
		for z: Dictionary in w.zombies:
			if float(z.hp) > 0 and w.routes.rectangle(w.definition("garden").rect).has_point(z.pos) and w.player.pos.distance_to(z.pos) < nearest:
				nearest = w.player.pos.distance_to(z.pos)
				target = z.pos
		w.move_input = w.player.pos.direction_to(w.routes.waypoint(w.player.pos, target)) if nearest > 45 else Vector2.ZERO
		_fight(w)
		w.step(0.05)
		if w.remaining("garden") == 0:
			break
	w.move_input = Vector2.ZERO
	if not _travel(w, Vector2(1080, 350)):
		return "Cannot return to cleared garden porch."
	if w.remaining("garden") != 0:
		return "Cannot clear garden through normal melee commands."
	w.interact()
	if not w.properties.garden.claimed:
		return "Cannot claim cleared garden at porch."
	w.interact()
	w.working = true
	# Clear threats near the worksite too: pursuit can draw in outside shamblers.
	for i: int in range(2400):
		var site := Vector2(1080, 350)
		var target: Vector2 = site
		var nearest: float = INF
		for z: Dictionary in w.zombies:
			if float(z.hp) > 0 and z.pos.distance_to(site) < 170 and w.player.pos.distance_to(z.pos) < nearest:
				nearest = w.player.pos.distance_to(z.pos)
				target = z.pos
		w.move_input = w.player.pos.direction_to(w.routes.waypoint(w.player.pos, target)) if (nearest > 45 and nearest < INF) or (nearest == INF and w.player.pos.distance_to(site) > 8) else Vector2.ZERO
		_fight(w)
		w.step(0.05)
		if w.garden_done:
			break
	w.move_input = Vector2.ZERO
	if not w.garden_done or w.downs != 0:
		return "Garden loop incomplete: built=%s, progress=%s, downs=%s, hp=%s, elapsed=%s." % [w.garden_done, w.garden_progress, w.downs, w.player.hp, w.elapsed]
	return ""


func _travel(w: RefCounted, destination: Vector2) -> bool:
	for i: int in range(800):
		if w.player.pos.distance_to(destination) < 8:
			w.move_input = Vector2.ZERO
			return true
		var next: Vector2 = w.routes.waypoint(w.player.pos, destination)
		w.move_input = w.player.pos.direction_to(next)
		_fight(w)
		w.step(0.05)
	w.move_input = Vector2.ZERO
	return false


func _fight(w: RefCounted) -> void:
	var distance: float = 230
	for z: Dictionary in w.zombies:
		var next: float = w.player.pos.distance_to(z.pos)
		if float(z.hp) > 0 and next < distance:
			distance = next
			w.aim = w.player.pos.direction_to(z.pos)
	w.attack()
