extends SceneTree
## Industrial works check: the final area boots and simulates, a Breaker lives in its depot, heavy waves become eligible once
## it is seen, the office exit leads in, and the main gate ends the campaign. Run: Godot --headless --path . --script res://tools/check_industrial.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const AreaTravel = preload("res://scripts/core/area_travel.gd")
const World = preload("res://scripts/sim/world.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var failures: int = 0


func _init() -> void:
	var office: Dictionary = Catalog.read("office")
	var works: Dictionary = Catalog.read("industrial")
	var world := World.new(works)
	_expect("the works hold the Foreman and a resident Breaker", not Boss.find(world).is_empty() and _breakers(world) == 1)
	_expect("it is the last area", Boss.destination(works) == "" and Boss.origin(works) == "office" and Facility.has(works, "garage") and not Facility.has(works, "garden"))
	world.player.hp = 100.0
	for lot: Dictionary in works.properties:
		world.player.pos = Routes.point(lot.site)
		_expect("%s offers a prompt without error" % lot.id, world.context() is String)
		for i: int in range(20):
			world.step(0.05)
	var saves := SaveState.new(works, "user://check_industrial.json")
	_expect("the works save and load", saves.restore(JSON.parse_string(JSON.stringify(saves.snapshot(world)))) != null)
	_expect("a Breaker is a template only once taught", _breaker_template_eligible(world, false) == false and _breaker_template_eligible(world, true))
	var office_world := World.new(office)
	Boss.find(office_world).hp = 0.0
	office_world.player.pos = Boss.exit_rect(office).get_center()
	office_world.step(0.1)
	office_world.interact()
	office_world.interact()
	_expect("the office exit asks for the works", office_world.travel_requested == "industrial")
	var arrived: RefCounted = AreaTravel.travel(office_world, SaveState.new(office, "user://check_industrial.json"), works)
	_expect("travel arrives at the works' service road", arrived != null and Boss.at_entrance(arrived))
	Boss.find(arrived).hp = 0.0
	arrived.player.pos = Boss.exit_rect(works).get_center()
	arrived.step(0.1)
	arrived.interact()
	_expect("the main gate ends the campaign with its line", arrived.campaign_ended and arrived.travel_requested == "")
	quit(failures)


func _breakers(world: RefCounted) -> int:
	var count: int = 0
	for z: Dictionary in world.zombies:
		count += 1 if z.get("kind") == "breaker" and float(z.hp) > 0 else 0
	return count


func _breaker_template_eligible(world: RefCounted, taught: bool) -> bool:
	var Plan: GDScript = load("res://scripts/sim/migration_plan.gd")
	world.pressure.taught = ["brute", "runner", "breaker"] if taught else ["brute", "runner"]
	world.pressure.band = 3
	for i: int in range(60):
		if Plan.composition(world, 20).template == "furnace_breaker":
			return true
	return false


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
