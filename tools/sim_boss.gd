extends SceneTree
## Scripted kiting fight against each area's boss: how long a competent player with the starting bat needs, and what it costs.
## Not a pass/fail check. Run: Godot --headless --path . --script res://tools/sim_boss.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Routes = preload("res://scripts/sim/routes.gd")


func _init() -> void:
	for area: String in ["suburb", "office", "industrial"]:
		for dodge: bool in [true, false]:
			_fight(area, dodge)
	quit()


func _fight(area: String, dodge: bool) -> void:
	var data: Dictionary = Catalog.read(area)
	var world := World.new(data)
	var boss: Dictionary = Boss.find(world)
	for z: Dictionary in world.zombies:
		if z != boss:
			z.hp = 0.0
	for s: Dictionary in world.survivors:
		s.hp = 0.0
	world.player.hp = float(data.balance.player_health)
	var side := Vector2(1, 0)
	for candidate: Vector2 in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
		if world.routes.walkable(boss.pos + candidate * 200) and world.routes.line_clear(boss.pos + candidate * 200, boss.pos, true) and world.routes.line_clear(boss.pos + candidate * 60, boss.pos, true):
			side = candidate
			break
	world.player.pos = boss.pos + side * 200
	var lowest: float = 1000.0
	var t: float = 0.0
	var step: float = float(world.balance.step)
	while t < 300.0 and float(boss.hp) > 0 and float(world.player.hp) > 0:
		var offset: Vector2 = world.player.pos - boss.pos
		var d: float = offset.length()
		var away: Vector2 = offset.normalized()
		var move := Vector2.ZERO
		var phase: String = str(boss.runner.phase)
		if dodge and phase in ["tell", "dash"]:
			var lane: Vector2 = Vector2(float(boss.runner.dx), float(boss.runner.dy)) if phase == "dash" else boss.facing
			move = lane.orthogonal() * (1.0 if offset.dot(lane.orthogonal()) >= 0 else -1.0)
		elif d < 52:
			move = away
		elif d > 70:
			move = -away
		world.move_input = move
		world.aim = -away
		world.step(step)
		if d < 74 and not (dodge and phase in ["tell", "dash"]):
			world.aim = -away
			world.attack()
		lowest = minf(lowest, float(world.player.hp))
		t += step
	print("%-10s %-9s %s in %5.1fs, player health left %3d (lowest %3d), boss left %4d" % [area, "dodging" if dodge else "no dodge", "WON " if float(boss.hp) <= 0 else "LOST", t, int(world.player.hp), int(lowest), int(maxf(0.0, float(boss.hp)))])
