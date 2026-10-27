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
	if w.claim("garden") or w.materials != before + 6:
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
	if w.materials != 16:
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
	if not restored.garden_done or restored.materials != 16:
		return "Saved work failed to finish exactly once after handoff."
	return ""


func check_home_guard_defends_while_player_is_away():
	var w := World.new(Catalog.read())
	w.player.pos = Vector2(1080, 350)
	for i: int in range(2200):
		w.step(0.05)
	var living: int = 0
	for z: Dictionary in w.zombies:
		if z.raid and float(z.hp) > 0:
			living += 1
	if not w.approach or living != 0 or float(w.properties.home.gate_hp) <= 0 or float(w.survivors[0].hp) <= 0:
		return "Guard failed to hold routine approach while player was elsewhere."
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
