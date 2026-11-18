extends SceneTree
## Scripted run to the ending: a headless bot plays every area in campaign order. In each it first reclaims the
## area's `objective.reclaim` lots (clear the yard, search the porch, claim it), then fights its way to the boss,
## kills it, takes the exit and travels on, until the last exit ends the campaign (--rush skips the reclaim). It fails
## on a stall (no progress toward the current objective), an unreachable boss or exit, or running out of time.
## It finds blockers before a human playtest; it does not judge balance. By default it tops the player's health
## up and recovers from defeat (counted in the report); pass --fair to stop at the first defeat instead.
## Run: Godot --headless --path . --script res://tools/bot_ending.gd [-- --seeds=1,2,3] [--fair] [--trace] [--rush]
## --trace prints where the player is once a simulated minute.
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const AreaTravel = preload("res://scripts/core/area_travel.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Defeat = preload("res://scripts/sim/defeat.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const SliceObjective = preload("res://scripts/sim/slice_objective.gd")
const STEP: float = 0.1
const AREA_MINUTES: float = 30.0
const STALL_SECONDS: float = 120.0
const PROGRESS: float = 60.0
const SAVE_PATH: String = "user://bot_ending.json"
var failures: int = 0
var fair: bool = false
var trace: bool = false
var rush: bool = false


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
		elif argument == "--rush":
			rush = true
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
		var step: Dictionary = {} if rush else _reclaim_step(world)
		if not step.is_empty():
			target = step.pos
			label = step.label
		elif not rush and not report.has("ready_" + world.area):
			report["ready_" + world.area] = true
			var unmet: String = SliceObjective.readiness(world)
			print("      %s reclaimed at %ds%s" % [world.area, int(world.elapsed), (", still unmet: " + unmet) if not unmet.is_empty() else ", readiness met"])
		if label != objective:
			objective = label
			best = INF
			since_progress = 0.0
		var foe: Dictionary = _fight(world)
		var fighting: bool = not foe.is_empty()
		var foe_hp: float = float(foe.get("hp", 0.0))
		if not step.is_empty() and bool(step.act) and not fighting:
			world.move_input = Vector2.ZERO
			world.interact()
		elif not alive and Boss.at_exit(world):
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


## The next move on the reclaim objective: the first listed lot not yet held that borders held ground (a claim needs a
## connected neighbour). Clear its yard (walk at the nearest zombie inside), then search and claim it at its porch.
## `act` is true when standing at the porch. {} when every listed lot is held or none can be reached yet.
func _reclaim_step(world: RefCounted) -> Dictionary:
	for id: String in world.catalog.objective.reclaim:
		var state: Dictionary = world.properties[id]
		if id == "home" or state.claimed:
			continue
		if not world.definition(id).neighbors.any(func(next: String) -> bool: return world.connected(next)):
			continue
		var p: Dictionary = world.definition(id)
		var yard: Rect2 = Routes.rectangle(p.rect)
		if world.remaining(id) > 0:
			var nearest: Vector2 = Vector2.INF
			for z: Dictionary in world.zombies:
				if float(z.hp) > 0 and yard.has_point(z.pos) and (not nearest.is_finite() or world.player.pos.distance_to(z.pos) < world.player.pos.distance_to(nearest)):
					nearest = z.pos
			return {"label": "clear " + id, "pos": nearest, "act": false}
		var site: Vector2 = Routes.point(p.site)
		return {"label": ("search " if not state.looted else "claim ") + id, "pos": site, "act": world.player.pos.distance_to(site) < 60.0}
	return {}


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
