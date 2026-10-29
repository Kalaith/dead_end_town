extends SceneTree
## Facility check: code finds facilities by kind. With any one facility missing from the area the sim, the prompts and a
## save round trip still work, and a facility moved to another lot is found there.
## Run: Godot --headless --path . --script res://tools/check_facilities.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Roster = preload("res://scripts/sim/roster.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	for kind: String in Facility.KINDS:
		if kind != "home":
			_without(data, kind)
	_moved(data)
	quit(failures)


func _without(data: Dictionary, kind: String) -> void:
	var variant: Dictionary = data.duplicate(true)
	for p: Dictionary in variant.properties:
		if p.facility == kind:
			p.facility = Facility.HOUSE
	var world := World.new(variant)
	var ok: bool = not Facility.has(variant, kind) and not Facility.state(world, kind).claimed
	for lot: Dictionary in variant.properties:
		world.player.pos = Routes.point(lot.site)
		world.player.hp = 100.0
		ok = ok and world.context() is String
		for i: int in range(20):
			world.step(0.05)
	ok = ok and world.garden_tended() is bool
	var saves := SaveState.new(variant, "user://check_facilities.json")
	var raw: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(world)))
	ok = ok and saves.restore(raw) != null
	_expect("an area without %s runs, prompts and saves" % kind, ok)


## The clinic facility moves to another lot; June, whose rescue site is "clinic", is then found there.
func _moved(data: Dictionary) -> void:
	var variant: Dictionary = data.duplicate(true)
	for p: Dictionary in variant.properties:
		if p.id == "clinic":
			p.facility = Facility.HOUSE
		elif p.id == "house_e":
			p.facility = "clinic"
	var world := World.new(variant)
	_expect("the clinic facility resolves to its new lot", Facility.id(variant, "clinic") == "house_e")
	world.properties.house_e.looted = true
	world.properties.house_e.claimed = true
	Roster.recruit(world, "june")
	var june: Dictionary = Roster.person(world, "june")
	var site: Vector2 = Routes.point(world.definition("house_e").site)
	_expect("June appears at the lot that now holds the clinic", not june.is_empty() and june.pos.distance_to(site) < 200.0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
