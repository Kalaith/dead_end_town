extends SceneTree
## Boss check: the baboon holds its post, charges with a tell, is leashed, and its death opens the exit and survives saving.
## Run: Godot --headless --path . --script res://tools/checks/check_boss.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	var world := World.new(data)
	var post: Vector2 = Routes.point(data.boss.post)
	var boss: Dictionary = Boss.find(world)
	_expect("the baboon waits at its post with escorts", not boss.is_empty() and boss.pos.is_equal_approx(post) and Boss.resident_ids(data).size() == 3)
	_expect("the exit is shut while it lives", not Boss.defeated(world))
	world.player.hp = 100000.0
	world.player.pos = post + Vector2(float(data.boss.leash) + 400.0, 0)
	_run(world, 20.0)
	_expect("it stays at its post when nobody is near", boss.pos.distance_to(post) < 40.0)
	world.player.pos = post + Vector2(150, 0)
	var phases: Array[String] = []
	for i: int in range(120):
		world.step(0.1)
		world.player.pos = post + Vector2(150, 0)
		if boss.runner.phase not in phases:
			phases.append(str(boss.runner.phase))
	_expect("it shows a charge tell before it charges", phases.has("tell") and phases.has("dash"))
	world.player.pos = post + Vector2(float(data.boss.leash) + 300.0, 0)
	_run(world, 30.0)
	_expect("it is not drawn beyond its leash", boss.pos.distance_to(post) <= float(data.boss.leash) + 40.0)
	world.player.hp = float(data.balance.player_health)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(SaveState.new(data, "user://check_boss.json").snapshot(world)))
	var saves := SaveState.new(data, "user://check_boss.json")
	_expect("a living boss round trips", saves.restore(raw.duplicate(true)) != null)
	var old: Dictionary = raw.duplicate(true)
	old.zombies = old.zombies.filter(func(z: Dictionary) -> bool: return z.home != Boss.HOME)
	old.schema_version = 36
	var upgraded: RefCounted = saves.restore(old)
	_expect("a schema 36 save gains the baboon at its post", upgraded != null and not Boss.find(upgraded).is_empty())
	boss.hp = 0.0
	world.step(0.1)
	_expect("its death opens the exit", Boss.defeated(world))
	world.player.pos = Boss.exit_rect(data).get_center()
	_expect("the exit can be reached", Boss.at_exit(world))
	var dead: RefCounted = saves.restore(JSON.parse_string(JSON.stringify(saves.snapshot(world))))
	_expect("the kill is permanent across a save", dead != null and Boss.defeated(dead))
	quit(failures)


func _run(world: RefCounted, seconds: float) -> void:
	for i: int in range(int(seconds * 10.0)):
		world.step(0.1)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
