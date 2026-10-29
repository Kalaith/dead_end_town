extends SceneTree
## Travel check: leaving needs the boss dead and a confirmation, people, gear and capped stock travel, the area left is
## frozen whole, and the same exit brings the player back. The second area is the real office district.
## Run: Godot --headless --path . --script res://tools/check_travel.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const AreaTravel = preload("res://scripts/core/area_travel.gd")
const World = preload("res://scripts/sim/world.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Roster = preload("res://scripts/sim/roster.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	var annex: Dictionary = Catalog.read("office")
	var saves := SaveState.new(data, "user://check_travel.json")
	var world := World.new(data)
	_expect("the destination is the next area in order", Boss.destination(data) == "office" and Boss.destination(annex) == "industrial")
	world.player.pos = Boss.exit_rect(data).get_center()
	world.interact()
	_expect("the baboon blocks the exit while it lives", world.travel_requested == "" and world.exit_pending == 0.0)
	Boss.find(world).hp = 0.0
	world.step(0.1)
	world.interact()
	_expect("the first press only asks", world.travel_requested == "" and world.exit_pending > 0.0 and world.context().contains("confirm"))
	world.step(Boss.CONFIRM_SECONDS + 1.0)
	_expect("the question lapses", world.exit_pending == 0.0)
	world.interact()
	world.interact()
	_expect("a second press confirms", world.travel_requested == "office")
	world.materials = 100
	world.food = 5
	world.properties.residence.looted = true
	world.firearms.owned = true
	world.firearms.bullets = 70
	world.properties.garage.looted = true
	world.equipment.crowbar = "you"
	var team: int = world.survivors.size()
	world.properties.library.looted = true
	Roster.recruit(world, "paige")
	world.rescue_intro = ""
	team = world.survivors.size()
	var arrived: RefCounted = AreaTravel.travel(world, saves, annex)
	_expect("travel produces the new area", arrived != null and arrived.area == "office")
	_expect("the team and gear come along", arrived.survivors.size() == team and arrived.equipment.crowbar == "you" and "crowbar" in arrived.unlocks and arrived.firearms.owned)
	_expect("stock is capped by the carry limit", arrived.materials == int(data.balance.area_carry_cap) + int(data.balance.starting_materials) and arrived.food == 5 + int(data.balance.starting_food))
	_expect("the area left is frozen with the surplus", arrived.frozen.has("suburb") and arrived.frozen.suburb.materials == 60)
	_expect("the way back names the stores waiting", Boss.waiting(arrived).contains("60 materials"))
	_expect("arrival says what was left behind", arrived.messages.any(func(m: String) -> bool: return m.begins_with("Left behind in")))
	var annex_saves := SaveState.new(annex, "user://check_travel.json")
	_expect("the new area saves and loads", annex_saves.restore(JSON.parse_string(JSON.stringify(annex_saves.snapshot(arrived)))) != null)
	_round_trip(data, annex)
	quit(failures)


## A clean world goes out and comes back by the same exit; nothing about the first area is lost.
func _round_trip(data: Dictionary, annex: Dictionary) -> void:
	var saves := SaveState.new(data, "user://check_travel.json")
	var annex_saves := SaveState.new(annex, "user://check_travel.json")
	var world := World.new(data)
	Boss.find(world).hp = 0.0
	world.materials = 55
	var out: RefCounted = AreaTravel.travel(world, saves, annex)
	var back: RefCounted = AreaTravel.travel(out, annex_saves, data)
	_expect("the exit leads back to the frozen area", back != null and back.area == "suburb" and back.frozen.has("office") and not back.frozen.has("suburb"))
	_expect("the first area is as it was left", back != null and Boss.defeated(back) and back.materials == 55 and back.survivors.size() == world.survivors.size())
	_expect("the player arrives at the exit they used", back != null and Boss.at_exit(back))
	# Time spent in the second area counts as time away from the first: a finished garden grows food meanwhile.
	var w2 := World.new(data)
	Boss.find(w2).hp = 0.0
	w2.garden_started = true
	w2.garden_done = true
	w2.garden_progress = float(data.balance.work_seconds)
	w2.properties.garden.looted = true
	w2.properties.garden.claimed_once = true
	w2.properties.garden.claimed = true
	w2.food = 0
	var away: RefCounted = AreaTravel.travel(w2, saves, annex)
	away.elapsed = 900.0
	var carried_food: int = away.food
	var home: RefCounted = AreaTravel.travel(away, annex_saves, data)
	_expect("a garden grows food while you are away (%d)" % (home.food if home != null else -1), home != null and home.food == carried_food + 10)



func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
