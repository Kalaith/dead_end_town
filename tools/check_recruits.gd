extends SceneTree
## Search-found survivors: Theo, Nia and Rowan join when their lot is searched, travel and save. Run:
## Godot --headless --path . --script res://tools/check_recruits.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Roster = preload("res://scripts/sim/roster.gd")
const AreaTravel = preload("res://scripts/core/area_travel.gd")
var failures: int = 0


func _init() -> void:
	for entry: Array in [["", ""], ["office", "theo"], ["industrial", "nia"], ["industrial", "rowan"]]:
		var data: Dictionary = Catalog.read(entry[0]) if not entry[0].is_empty() else Catalog.read()
		var world := World.new(data)
		var lot: String = ""
		for p: Dictionary in data.properties:
			if p.has("search") and p.search.survivor == entry[1] and not entry[1].is_empty():
				lot = p.id
		if entry[1].is_empty():
			_expect("the suburb recruits none of the three", Roster.recruit(world, "theo") == false and Roster.person(world, "theo").is_empty())
			continue
		_expect("%s is found in a lot of the %s" % [entry[1], entry[0]], not lot.is_empty())
		_expect("%s is not there before the search" % entry[1], not Roster.recruit(world, entry[1]) and Roster.person(world, entry[1]).is_empty())
		for z: Dictionary in world.zombies:
			z.hp = 0.0
		world.player.pos = Vector2(world.definition(lot).site[0], world.definition(lot).site[1])
		world.player.hp = 100.0
		world.interact()
		_expect("searching the lot recruits %s" % entry[1], not Roster.person(world, entry[1]).is_empty() and world.rescue_intro == entry[1])
		var saves := SaveState.new(data, "user://check_recruits.json")
		var loaded: RefCounted = saves.restore(JSON.parse_string(JSON.stringify(saves.snapshot(world))))
		_expect("%s survives a save" % entry[1], loaded != null and not Roster.person(loaded, entry[1]).is_empty())
	_check_early_search()
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1


## A save whose lot was searched before its survivor was written in: loading it, or coming back to that area, finds them.
func _check_early_search() -> void:
	var office: Dictionary = Catalog.read("office")
	var lot: String = ""
	for p: Dictionary in office.properties:
		if p.has("search") and p.search.survivor == "theo":
			lot = p.id
	var world := World.new(office)
	world.properties[lot].looted = true
	var saves := SaveState.new(office, "user://check_recruits.json")
	saves.store.enabled = false
	var old: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(world)))
	_expect("an early-searched lot holds no Theo before loading", Roster.person(world, "theo").is_empty())
	var loaded: RefCounted = saves.restore(old)
	_expect("loading that save finds Theo at his lot", loaded != null and not Roster.person(loaded, "theo").is_empty() and loaded.rescue_intro == "theo")
	_expect("a second catch-up recruits nobody", loaded != null and Roster.catch_up(loaded).is_empty())
	var works: Dictionary = Catalog.read("industrial")
	var away: RefCounted = AreaTravel.travel(world, saves, works)
	_expect("the office is left with its lot searched and no Theo", away != null and Roster.person(away, "theo").is_empty())
	if away == null:
		return
	var back: RefCounted = AreaTravel.travel(away, SaveState.new(works, "user://check_recruits.json"), office)
	_expect("coming back to the office finds Theo there", back != null and not Roster.person(back, "theo").is_empty())
