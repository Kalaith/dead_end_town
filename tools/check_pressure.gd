extends SceneTree
## Pressure check: the first event enters at the bridge route, in the right band, and the horde moves into the area.
## Run: Godot --headless --path . --script res://tools/check_pressure.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const Plan = preload("res://scripts/sim/migration_plan.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Readiness = preload("res://scripts/sim/readiness.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	var world := World.new(data)
	var route: Dictionary = data.pressure.routes[0]
	var entry: Vector2 = Routes.point(route.entry)
	_expect("readiness summary describes stock, perimeter and defenders", Readiness.summary(world).contains("Food") and Readiness.summary(world).contains("Barricades") and Readiness.summary(world).contains("Defenders"))
	_expect("band starts at 0 with nothing claimed beyond home", Plan.band(data, world.properties) == 0)
	_claim_neighbour(world)
	_expect("first claim schedules an event", world.pressure.phase == "waiting" and not world.pressure.event.is_empty())
	var event: Dictionary = world.pressure.event
	_expect("event enters from the bridge route only", event.entries == [route.id])
	var limit: float = world.elapsed + 600.0
	var admitted: Array[Dictionary] = []
	var spawn: Vector2 = Vector2.ZERO
	while world.elapsed < limit and admitted.size() < 3:
		world.step(0.1)
		admitted.clear()
		for z: Dictionary in world.zombies:
			if z.raid:
				admitted.append(z)
		if admitted.size() == 1 and spawn == Vector2.ZERO:
			spawn = admitted[0].pos
	_expect("zombies are admitted within ten minutes", admitted.size() >= 3)
	var finish: float = world.elapsed + 60.0
	while world.elapsed < finish and world.pressure.last.is_empty():
		world.step(0.1)
	_expect("the first event enters whole, not thinned by spawn overlap", not world.pressure.last.is_empty() and int(world.pressure.last.skipped) == 0)
	if admitted.size() >= 3:
		_expect("admitted at the bridge entry", spawn.distance_to(entry) < 120.0)
		var start: float = spawn.distance_to(Routes.point(world.catalog.balance.player_start))
		for i: int in range(600):
			world.step(0.1)
		var after: float = admitted[0].pos.distance_to(Routes.point(world.catalog.balance.player_start))
		_expect("the horde advances toward the settlement", after < start)
		var stuck: int = 0
		for z: Dictionary in world.zombies:
			if z.raid and float(z.hp) > 0 and z.pos.y > float(world.catalog.balance.home_respawn[1]) + 1500.0 and z.pos.x > 700.0:
				stuck += 1
		_expect("no raider strays east of the bridge and west road (%d)" % stuck, stuck == 0)
	quit(failures)


func _claim_neighbour(world: RefCounted) -> void:
	for id: String in world.definition("home").neighbors:
		world.properties[id].claimed = true
		world.properties[id].claimed_once = true
		world.properties[id].looted = true
		Pressure.claimed(world, id)
		return


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
