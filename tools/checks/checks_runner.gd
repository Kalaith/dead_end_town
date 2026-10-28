extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Runner = preload("res://scripts/sim/runner.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const SaveState = preload("res://scripts/core/save_state.gd")


static func prepared() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for a: Dictionary in w.survivors:
		a.pos = Vector2(360, 350)
		a.order = "Hold"
		a.anchor = a.pos
	w.player.pos = Vector2(2490, 580)
	w.aim = Vector2.RIGHT
	w.player.facing = Vector2.RIGHT
	var z: Dictionary = runner(w)
	z.hp = 45.0
	z.pos = w.player.pos + Vector2(100, 0)
	z.cooldown = 0.0
	z.runner = Runner.initial()
	return w


static func runner(w: RefCounted) -> Dictionary:
	for z: Dictionary in w.zombies:
		if z.id == "resident_hardware_0":
			return z
	return {}


static func ticks(w: RefCounted, count: int) -> void:
	for i: int in range(count):
		w.step(0.05)


func check_runner_tell_commit_miss_and_harmless_recovery() -> String:
	var w: RefCounted = prepared()
	var z: Dictionary = runner(w)
	w.step(0.05)
	var start: Vector2 = z.pos
	if z.runner.phase != "tell" or z.runner.left != 0.7:
		return "Runner did not start its full tell."
	w.player.pos += Vector2(0, 90)
	ticks(w, 13)
	if z.pos != start or z.runner.phase != "tell":
		return "Runner moved before its tell elapsed."
	ticks(w, 9)
	if z.runner.phase != "recover" or absf(z.pos.y - start.y) > 0.001 or absf(start.x - z.pos.x - 85) > 0.001 or w.player.hp != 100.0:
		return "Miss homed, travelled too far or damaged a sidestep."
	w.player.pos = z.pos
	var retry: float = float(z.runner.retry)
	ticks(w, 10)
	if w.player.hp != 100.0 or z.runner.phase != "recover" or z.runner.retry >= retry:
		return "Recovery damaged a person or froze the cooldown."
	return ""


func check_runner_hits_once_and_shield_faces_source() -> String:
	for shield: bool in [false, true]:
		var w: RefCounted = prepared()
		var z: Dictionary = runner(w)
		w.player.facing = Vector2.RIGHT
		if shield:
			w.properties.garage.claimed = true
			w.properties.garage.looted = true
			w.equipment.shield = "you"
		ticks(w, 22)
		var expected: float = 8.0 * (float(w.balance.shield_damage_multiplier) if shield else 1.0)
		if not is_equal_approx(float(w.player.hp), 100.0 - expected) or z.runner.phase != "recover":
			return "Dash did not resolve one shield-aware hit."
		ticks(w, 8)
		if not is_equal_approx(float(w.player.hp), 100.0 - expected):
			return "Dash/recovery duplicated contact damage."
	return ""


func check_runner_stops_at_fence_gate_low_barrier_and_ally() -> String:
	for obstacle: String in ["fence", "gate", "barricade", "ally"]:
		var w: RefCounted = prepared()
		var z: Dictionary = runner(w)
		if obstacle == "fence":
			z.pos = Vector2(2480, 450)
			z.runner.dx = 0.0
			z.runner.dy = 1.0
		elif obstacle == "gate":
			w.properties.hardware.open = false
			w.rebuild_routes()
			z.pos = Vector2(2520, 440)
			z.runner.dx = 0.0
			z.runner.dy = 1.0
		elif obstacle == "barricade":
			w.routes.road_walls.append(Rect2(2540, 530, 8, 100))
			z.runner.dx = -1.0
			z.runner.dy = 0.0
		else:
			w.zombies[0].hp = 60.0
			w.zombies[0].pos = z.pos + Vector2(-40, 0)
			z.runner.dx = -1.0
			z.runner.dy = 0.0
		z.runner.phase = "dash"
		z.runner.distance = 85.0
		var start: Vector2 = z.pos
		Runner.step(w, z, w.player, 1.0)
		if z.runner.phase != "recover" or z.pos.distance_to(start) > 45 or w.player.hp != 100.0 or not w.routes.walkable(z.pos):
			return "Dash passed through " + obstacle
	return ""


func check_runner_melee_interrupt_and_single_pistol_counter() -> String:
	var w: RefCounted = prepared()
	var z: Dictionary = runner(w)
	z.pos = w.player.pos + Vector2(65, 0)
	w.step(0.05)
	Combat.strike(w, w.player, Vector2.RIGHT)
	if z.runner.phase != "recover" or z.hp != 15.0:
		return "Bat did not interrupt the committed attack."
	w = prepared()
	z = runner(w)
	w.firearms.owned = true
	w.firearms.bullets = 6
	w.step(0.05)
	if not Firearms.shoot(w) or z.hp != 0 or w.firearms.bullets != 5:
		return "A pistol shot did not stop the Runner."
	return ""


func check_runner_every_phase_roundtrips_with_same_outcome() -> String:
	for count: int in [0, 1, 16, 22]:
		var w: RefCounted = prepared()
		ticks(w, count)
		var save := SaveState.new(w.catalog)
		var raw: Dictionary = JSON.parse_string(JSON.stringify(save.snapshot(w)))
		var loaded: RefCounted = save.restore(raw)
		if loaded == null:
			return "Runner phase rejected reload at tick %d" % count
		for i: int in range(30):
			w.step(0.05)
			loaded.step(0.05)
		if JSON.parse_string(JSON.stringify(save.snapshot(w))) != JSON.parse_string(JSON.stringify(save.snapshot(loaded))):
			return "Runner changed authoritative outcomes after reload at %d" % count
		var broken: Dictionary = raw.duplicate(true)
		for actor: Dictionary in broken.zombies:
			if actor.id == "resident_hardware_0":
				actor.runner.dx = 8.0
		if save.valid(broken):
			return "Invalid committed direction was accepted."
	return ""


func check_schema_thirty_one_upgrades_living_standins_without_repopulation() -> String:
	var w: RefCounted = prepared()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 31
	for z: Dictionary in old.zombies:
		if z.has("runner"):
			z.erase("runner")
			z.erase("kind")
			z.name = "Shambler"
			if z.id == "resident_hardware_0":
				z.hp = 30.0
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or runner(loaded).kind != "runner" or runner(loaded).hp != 30.0 or loaded.zombies.size() != w.zombies.size() or loaded.roam_rng.state != w.roam_rng.state or loaded.materials != w.materials:
		return "Migration lost partial health, actors, supplies or RNG."
	for z: Dictionary in loaded.zombies:
		if z.home == "greenhouse" and (z.hp != 0 or z.has("runner")):
			return "A depleted stand-in was repopulated or converted."
	return ""
