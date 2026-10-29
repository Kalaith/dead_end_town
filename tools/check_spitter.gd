extends SceneTree
## Spitter check: aims at a committed point, a glob lands and leaves a pool that does not stack, walls stop globs, a hit
## interrupts the aim, state validates and saves. Run: Godot --headless --path . --script res://tools/check_spitter.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Spitter = preload("res://scripts/sim/spitter.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read("office")
	var world := World.new(data)
	var spitters: Array[Dictionary] = []
	for z: Dictionary in world.zombies:
		if z.get("kind") == "spitter":
			spitters.append(z)
	_expect("the office holds a resident Spitter", spitters.size() == 1 and spitters[0].has("spitter"))
	# Isolate one spitter and the player on open ground.
	var s: Dictionary = spitters[0]
	for z: Dictionary in world.zombies:
		if z != s:
			z.hp = 0.0
	var open: Vector2 = _open_pair(world, 220.0)
	s.pos = open
	world.player.pos = open + Vector2(220, 0)
	world.player.hp = 100.0
	var start_hp: float = float(world.player.hp)
	for i: int in range(60):
		world.step(0.05)
		if s.spitter.phase == "aim":
			break
	_expect("it begins aiming at range with a clear shot", s.spitter.phase == "aim")
	var committed := Vector2(float(s.spitter.tx), float(s.spitter.ty))
	_expect("the aim point is the player's position when it began", committed.distance_to(open + Vector2(220, 0)) < 1.0)
	var saves := SaveState.new(data, "user://check_spitter.json")
	_expect("mid-aim state saves and loads", saves.restore(JSON.parse_string(JSON.stringify(saves.snapshot(world)))) != null)
	var cfg: Dictionary = data.zombies.types.spitter
	world.player.pos = committed + Vector2(0, 300)
	for i: int in range(int(float(cfg.spit_tell) / 0.05) + 2):
		world.step(0.05)
	_expect("a glob was released after the tell", world.spits.size() >= 1)
	var pooled: bool = false
	for i: int in range(120):
		world.step(0.05)
		for h: Dictionary in world.spits:
			if h.t == "pool":
				pooled = true
		if pooled:
			break
	_expect("the glob lands and leaves a pool", pooled)
	world.player.hp = 100.0
	for h: Dictionary in world.spits:
		if h.t == "pool":
			world.player.pos = Vector2(float(h.x), float(h.y))
			world.spits = [h]
			break
	s.pos = Vector2(-5000, -5000)
	s.hp = 0.0
	world.player.hp = 100.0
	world.spits.append({"t": "pool", "x": world.player.pos.x, "y": world.player.pos.y, "age": 0.0, "tick": 1.0})
	for i: int in range(100):
		world.step(0.05)
	var taken: float = 100.0 - float(world.player.hp)
	_expect("two overlapping pools deal at most 16 damage (shared cooldown): %.0f" % taken, taken > 0.0 and taken <= 16.0)
	_expect("pools expire", world.spits.is_empty())
	var wall: Rect2 = world.routes.walls[0]
	var w2 := World.new(data)
	w2.spits.append({"t": "glob", "x": wall.position.x - 30.0, "y": wall.get_center().y, "tx": wall.end.x + 60.0, "ty": wall.get_center().y})
	for i: int in range(60):
		Spitter.advance(w2, 0.05)
	var behind: bool = false
	for h: Dictionary in w2.spits:
		if float(h.x) > wall.end.x:
			behind = true
	_expect("a wall stops a glob", not behind)
	_hazards(data)
	var bad := World.new(data)
	var z2: Dictionary = bad.zombies[0]
	Pressure.give_kind(data, z2, "spitter")
	_expect("a fresh spitter state validates", SaveState.new(data, "user://check_spitter.json").restore(JSON.parse_string(JSON.stringify(SaveState.new(data, "user://check_spitter.json").snapshot(bad)))) != null)
	z2.spitter.phase = "aim"
	z2.spitter.left = 0.0
	_expect("an aim with no time left is invalid", SaveState.new(data, "user://check_spitter.json").restore(JSON.parse_string(JSON.stringify(SaveState.new(data, "user://check_spitter.json").snapshot(bad)))) == null)
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


## Survivors step out of pools and aim points, and hazards survive a save.
func _hazards(data: Dictionary) -> void:
	var world := World.new(data)
	for z: Dictionary in world.zombies:
		z.hp = 0.0
	var spot: Vector2 = _open_pair(world, 220.0)
	var mara: Dictionary = world.survivors[0]
	mara.order = "Hold"
	mara.anchor = spot
	mara.pos = spot
	mara.hp = 100.0
	world.player.pos = spot + Vector2(0, 400)
	world.spits = [{"t": "pool", "x": spot.x, "y": spot.y, "age": 0.0, "tick": 1.0}]
	var radius: float = float(data.zombies.types.spitter.pool_radius)
	_expect("someone in a pool has somewhere to go", Spitter.escape(world, spot).is_finite())
	_expect("someone clear of it is left alone", not Spitter.escape(world, spot + Vector2(300, 0)).is_finite())
	for i: int in range(40):
		world.step(0.05)
	_expect("a survivor walks out of the pool", mara.pos.distance_to(spot) > radius)
	world.spits = [{"t": "glob", "x": spot.x - 80.0, "y": spot.y, "tx": mara.pos.x, "ty": mara.pos.y}, {"t": "pool", "x": spot.x, "y": spot.y, "age": 1.5, "tick": 2.0}]
	var saves := SaveState.new(data, "user://check_spitter.json")
	var loaded: RefCounted = saves.restore(JSON.parse_string(JSON.stringify(saves.snapshot(world))))
	_expect("globs and pools survive a save", loaded != null and loaded.spits.size() == 2 and loaded.spits[0].t == "glob" and is_equal_approx(float(loaded.spits[1].age), 1.5))
	world.spits = [{"t": "pool", "x": 10.0, "y": 10.0, "age": 99.0, "tick": 1.0}]
	_expect("an over-age pool is rejected", saves.restore(JSON.parse_string(JSON.stringify(saves.snapshot(world)))) == null)


func _open_pair(world: RefCounted, gap: float) -> Vector2:
	for x: int in range(200, 1500, 40):
		for y: int in range(200, 2200, 40):
			var a := Vector2(x, y)
			var b := a + Vector2(gap, 0)
			if world.routes.walkable(a) and world.routes.walkable(b) and world.routes.line_clear(a, b, true) and world.routes.line_clear(a, a + Vector2(0, 0), true):
				return a
	return Vector2(400, 400)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
