extends SceneTree
## Office district check: the second area boots and simulates on its own ids, saves and loads, has its warden and gates,
## and the real suburb exit leads in and the office entrance leads back. Run: Godot --headless --path . --script res://tools/check_office.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const AreaTravel = preload("res://scripts/core/area_travel.gd")
const World = preload("res://scripts/sim/world.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var failures: int = 0


func _init() -> void:
	var suburb: Dictionary = Catalog.read("suburb")
	var office: Dictionary = Catalog.read("office")
	_alone(office)
	_journey(suburb, office)
	quit(failures)


func _alone(office: Dictionary) -> void:
	var world := World.new(office)
	_expect("the office has its own lot ids and facilities", Facility.id(office, "garden") == "roof_garden" and Facility.id(office, "clinic") == "first_aid" and not Facility.has(office, "greenhouse"))
	_expect("the warden waits at its post with escorts", not Boss.find(world).is_empty() and Boss.resident_ids(office).size() == 3)
	world.player.hp = 100.0
	for lot: Dictionary in office.properties:
		world.player.pos = Routes.point(lot.site)
		_expect("%s offers a prompt without error" % lot.id, world.context() is String)
		for i: int in range(20):
			world.step(0.05)
	for i: int in range(int(240.0 / 0.1)):
		world.player.hp = 100.0
		world.step(0.1)
	_expect("pressure runs from the south-east road", world.pressure.wave >= 0)
	var saves := SaveState.new(office, "user://check_office.json")
	var raw: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(world)))
	_expect("the office saves and loads", saves.restore(raw) != null)
	world.player.pos = Routes.rectangle(office.exit.rect).get_center()
	_expect("the exit is blocked and leads nowhere yet", world.context().contains("Blocked"))


func _journey(suburb: Dictionary, office: Dictionary) -> void:
	var saves := SaveState.new(suburb, "user://check_office.json")
	var world := World.new(suburb)
	Boss.find(world).hp = 0.0
	world.pressure.taught = ["runner"]
	world.player.pos = Boss.exit_rect(suburb).get_center()
	world.step(0.1)
	world.interact()
	world.interact()
	_expect("the suburb exit asks for the office", world.travel_requested == "office")
	var arrived: RefCounted = AreaTravel.travel(world, saves, office)
	_expect("travel brings the team to the office entrance", arrived != null and Boss.at_entrance(arrived))
	_expect("what the community has learned to expect travels with it", arrived != null and "runner" in arrived.pressure.taught)
	var office_saves := SaveState.new(office, "user://check_office.json")
	arrived.interact()
	_expect("the entrance asks before going back", arrived.travel_requested == "" and arrived.exit_pending > 0.0 and arrived.context().contains("confirm"))
	arrived.interact()
	_expect("a second press asks for the previous area", arrived.travel_requested == "suburb")
	var back: RefCounted = AreaTravel.travel(arrived, office_saves, suburb)
	_expect("going back arrives at the suburb exit", back != null and back.area == "suburb" and Boss.at_exit(back))
	var again: RefCounted = AreaTravel.travel(back, saves, office)
	_expect("going forward again restores the frozen office at its entrance", again != null and again.area == "office" and Boss.at_entrance(again))


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
