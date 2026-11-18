extends SceneTree
## Raid check: in every area, the first raid after a claim enters on its authored route and reaches a held gate.
## Raider targets all come from area data (route entry and approach, lot site, gate and yard), so each area is run.
## Run: Godot --headless --path . --script res://tools/checks/check_raids.gd [-- <area id>]
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const GATE_REACH: float = 90.0
const MINUTES: float = 20.0
var failures: int = 0


func _init() -> void:
	var registry: Dictionary = Catalog.registry()
	var only: PackedStringArray = OS.get_cmdline_user_args()
	for entry: Dictionary in registry.areas:
		if only.is_empty() or str(entry.id) in only:
			_area(str(entry.id))
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _area(id: String) -> void:
	var data: Dictionary = Catalog.read(id)
	if data.is_empty():
		_expect("%s loads" % id, false)
		return
	var world := World.new(data)
	var held: String = _claim_neighbour(world)
	_expect("%s: claiming %s schedules a raid" % [id, held], not world.pressure.event.is_empty())
	var gates: Array[Vector2] = [Routes.point(world.definition("home").gate), Routes.point(world.definition(held).gate)]
	var entries: Array[Vector2] = []
	for route: Dictionary in data.pressure.routes:
		entries.append(Routes.point(route.entry))
	var limit: float = world.elapsed + MINUTES * 60.0
	var first_spawn := Vector2.INF
	var reached: bool = false
	while world.elapsed < limit and not reached:
		world.player.hp = float(world.balance.player_health)
		world.step(0.1)
		for z: Dictionary in world.zombies:
			if not z.raid or float(z.hp) <= 0:
				continue
			if not first_spawn.is_finite():
				first_spawn = z.pos
			for gate: Vector2 in gates:
				if z.pos.distance_to(gate) < GATE_REACH:
					reached = true
	_expect("%s: raiders are admitted" % id, first_spawn.is_finite())
	if first_spawn.is_finite():
		var near_entry: bool = entries.any(func(e: Vector2) -> bool: return first_spawn.distance_to(e) < 150.0)
		_expect("%s: the first raider enters at an authored route" % id, near_entry)
	_expect("%s: a raider reaches a held gate within %d minutes (%ds)" % [id, int(MINUTES), int(world.elapsed)], reached)
	if not reached:
		_where(world, gates)


## On a failure, says where the living raiders stand and which lot they are in, to show where the path stops.
func _where(world: RefCounted, gates: Array[Vector2]) -> void:
	print("      held gates: %s" % str(gates))
	var shown: int = 0
	for z: Dictionary in world.zombies:
		if z.raid and float(z.hp) > 0 and shown < 12:
			var lot: String = "road"
			for p: Dictionary in world.catalog.properties:
				if Routes.rectangle(p.rect).has_point(z.pos):
					lot = p.id
			print("      %s at %s in %s" % [z.id, str(z.pos.round()), lot])
			shown += 1


## Claims the first of home's neighbours, as a player would, and returns its id.
func _claim_neighbour(world: RefCounted) -> String:
	for id: String in world.definition("home").neighbors:
		world.properties[id].claimed = true
		world.properties[id].claimed_once = true
		world.properties[id].looted = true
		Pressure.claimed(world, id)
		return id
	return ""


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
