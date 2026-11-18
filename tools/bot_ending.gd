extends SceneTree
## Scripted run to the ending: a headless bot plays every area in campaign order, walks out of home, fights its
## way to the area's boss, kills it, takes the exit and travels on, until the last exit ends the campaign. It fails
## on a stall (no progress toward the current objective), an unreachable boss or exit, or running out of time.
## It finds blockers before a human playtest; it does not judge balance. By default it tops the player's health
## up and recovers from defeat (counted in the report); pass --fair to stop at the first defeat instead.
## Run: Godot --headless --path . --script res://tools/bot_ending.gd [-- --seeds=1,2,3] [--fair] [--trace]
## --trace prints where the player is once a simulated minute.
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const AreaTravel = preload("res://scripts/core/area_travel.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Defeat = preload("res://scripts/sim/defeat.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const STEP: float = 0.1
const AREA_MINUTES: float = 30.0
const STALL_SECONDS: float = 120.0
const PROGRESS: float = 60.0
const SAVE_PATH: String = "user://bot_ending.json"
var failures: int = 0
var fair: bool = false
var trace: bool = false


func _init() -> void:
	var seeds: Array[int] = [1, 2, 3]
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--seeds="):
			seeds.clear()
			for part: String in argument.trim_prefix("--seeds=").split(","):
				seeds.append(int(part))
		elif argument == "--fair":
			fair = true
		elif argument == "--trace":
			trace = true
	for value: int in seeds:
		_run(value)
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


## One run from a new street to the ending screen.
func _run(value: int) -> void:
	var data: Dictionary = Catalog.read()
	var world: RefCounted = World.new(data)
	world.roam_rng.seed = value
	var saves: RefCounted = _saves(data)
	var report: Dictionary = {"heals": 0, "recoveries": 0, "lowest": float(world.balance.player_health)}
	while true:
		var outcome: String = _play_area(world, report)
		if outcome == "ended":
			print("pass  seed %d reaches the ending (%s)" % [value, _summary(report)])
			return
		if outcome != "travel":
			_fail("seed %d in %s: %s (%s)" % [value, world.area, outcome, _summary(report)])
			return
		var next: Dictionary = Catalog.read(world.travel_requested)
		var arrived: RefCounted = AreaTravel.travel(world, saves, next)
		if arrived == null:
			_fail("seed %d: travel from %s to %s failed" % [value, world.area, world.travel_requested])
			return
		print("      seed %d: %s done at %ds, on to %s" % [value, world.area, int(world.elapsed), next.area.id])
		world = arrived
		saves = _saves(next)


func _saves(data: Dictionary) -> RefCounted:
	var saves := SaveState.new(data, SAVE_PATH)
	saves.store.enabled = false
	return saves


## Plays one area until it asks to travel ("travel"), ends the campaign ("ended") or fails (the reason).
func _play_area(world: RefCounted, report: Dictionary) -> String:
	var limit: float = world.elapsed + AREA_MINUTES * 60.0
	var best: float = INF
	var since_progress: float = 0.0
	var objective: String = ""
	while world.elapsed < limit:
		if world.campaign_ended:
			return "ended"
		if world.travel_requested != "":
			return "travel"
		if world.defeat_pending or float(world.player.hp) <= 0:
			if fair:
				return "defeated"
			Defeat.recover(world)
			report.recoveries += 1
		report.lowest = minf(report.lowest, float(world.player.hp))
		if not fair and float(world.player.hp) < float(world.balance.player_health) * 0.5:
			world.player.hp = float(world.balance.player_health)
			report.heals += 1
		var boss: Dictionary = Boss.find(world)
		var alive: bool = not boss.is_empty() and float(boss.hp) > 0
		var target: Vector2 = boss.pos if alive else Boss.exit_rect(world.catalog).get_center()
		var label: String = "boss" if alive else "exit"
		if label != objective:
			objective = label
			best = INF
			since_progress = 0.0
		var foe: Dictionary = _fight(world)
		var fighting: bool = not foe.is_empty()
		var foe_hp: float = float(foe.get("hp", 0.0))
		if not alive and Boss.at_exit(world):
			world.move_input = Vector2.ZERO
			world.interact()
		elif not fighting:
			_walk(world, target)
		var distance: float = world.player.pos.distance_to(target)
		if distance < best - PROGRESS:
			best = distance
			since_progress = 0.0
		else:
			since_progress += STEP
		if since_progress > STALL_SECONDS:
			return "stalled at %s, %s %d px away at %s" % [str(world.player.pos.round()), objective, int(distance), str(target.round())]
		if trace and fmod(world.elapsed, 60.0) < STEP:
			print("      %ds %s at %s, %s %d px, last note: %s" % [int(world.elapsed), world.area, str(world.player.pos.round()), objective, int(distance), str(world.messages.back()) if not world.messages.is_empty() else ""])
		world.step(STEP)
		world.release_interact()
		# A fight that lands blows is progress; one that cannot hurt its target is a stall.
		if fighting and float(foe.hp) < foe_hp:
			since_progress = 0.0
	return "out of time going for the %s" % objective


## Swings at the nearest living zombie in reach and in the open (not behind a fence). Returns it, or {}.
func _fight(world: RefCounted) -> Dictionary:
	var reach: float = float(world.balance.attack_reach) + 12.0
	var nearest: Dictionary = {}
	var nearest_distance: float = INF
	for z: Dictionary in world.zombies:
		var distance: float = world.player.pos.distance_to(z.pos)
		if float(z.hp) > 0 and distance < nearest_distance and world.routes.line_clear(world.player.pos, z.pos, true):
			nearest = z
			nearest_distance = distance
	if nearest.is_empty() or nearest_distance > reach:
		return {}
	world.move_input = Vector2.ZERO
	world.aim = world.player.pos.direction_to(nearest.pos)
	world.attack()
	return nearest


## Steps toward `target` along the route grid, opening the gate of a closed yard the player stands in.
func _walk(world: RefCounted, target: Vector2) -> void:
	var next: Vector2 = world.routes.waypoint(world.player.pos, target)
	if next.is_equal_approx(world.player.pos) and not world.routes.line_clear(world.player.pos, target):
		var yard: Dictionary = _closed_yard(world)
		if not yard.is_empty():
			var gate: Vector2 = Routes.point(yard.gate)
			if world.player.pos.distance_to(gate) < 60.0:
				world.move_input = Vector2.ZERO
				world.interact()
				return
			next = gate + (Routes.rectangle(yard.rect).get_center() - gate).normalized() * 30.0
		else:
			next = target
	world.move_input = world.player.pos.direction_to(next)
	world.aim = world.move_input


func _closed_yard(world: RefCounted) -> Dictionary:
	for p: Dictionary in world.catalog.properties:
		if Routes.rectangle(p.rect).has_point(world.player.pos) and not world.properties[p.id].open:
			return p
	return {}


func _summary(report: Dictionary) -> String:
	return "%d heals, %d recoveries, lowest health %d" % [report.heals, report.recoveries, int(report.lowest)]


func _fail(label: String) -> void:
	print("FAIL  " + label)
	failures += 1
