extends SceneTree
## Search-found survivors: Theo, Nia and Rowan join when their lot is searched, travel and save. Run:
## Godot --headless --path . --script res://tools/check_recruits.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Roster = preload("res://scripts/sim/roster.gd")
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
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
