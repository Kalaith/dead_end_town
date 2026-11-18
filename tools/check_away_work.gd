extends SceneTree
## Away work check: while the player is in another area, a paid-for workshop restoration finishes and the ammunition
## bench keeps crafting under its policy, paying from the stock left behind. Run:
## Godot --headless --path . --script res://tools/check_away_work.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const AreaTravel = preload("res://scripts/core/area_travel.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Production = preload("res://scripts/sim/production.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	var annex: Dictionary = Catalog.read("office")
	var saves := SaveState.new(data, "user://check_away_work.json")
	var annex_saves := SaveState.new(annex, "user://check_away_work.json")
	saves.store.enabled = false
	annex_saves.store.enabled = false
	var world := World.new(data)
	Boss.find(world).hp = 0.0
	for id: String in ["garage", "munitions"]:
		world.properties[id].looted = true
		world.properties[id].claimed_once = true
		world.properties[id].claimed = true
	world.materials = 200
	var garage: Vector2 = Routes.point(world.definition("garage").site)
	_expect("the workshop restoration is paid for", WorkOrders.approve(world, "restore:workshop", "garage", WorkRecipes.recipe(data, "workshop"), garage))
	world.workshop.started = true
	_expect("the bench is set to keep 24 bullets", Production.configure(world, "repeat", 24, 6))
	var away: RefCounted = AreaTravel.travel(world, saves, annex)
	var left_materials: int = int(away.frozen.suburb.materials)
	away.elapsed = 900.0
	var back: RefCounted = AreaTravel.travel(away, annex_saves, data)
	_expect("travel back succeeds", back != null)
	if back == null:
		quit(1)
		return
	_expect("the workshop finished while you were away", back.workshop.done and not back.workshop.armour_done)
	var batch: int = int(data.firearm.batch_bullets)
	var batches: int = ceili(24.0 / float(batch))
	_expect("the bench made bullets up to its target (%d)" % int(back.firearms.bullets), int(back.firearms.bullets) == batches * batch)
	var carried_back: int = mini(int(away.materials), int(data.balance.area_carry_cap))
	_expect("each batch was paid from the stock left behind", back.materials == left_materials - batches * int(data.firearm.material_cost) + carried_back)
	_expect("no work is left credited to nobody", back.orders.sites.values().all(func(o: Dictionary) -> bool: return o.executor != "away"))
	var idle := World.new(data)
	Boss.find(idle).hp = 0.0
	var gone: RefCounted = AreaTravel.travel(idle, saves, annex)
	gone.elapsed = 900.0
	var still: RefCounted = AreaTravel.travel(gone, annex_saves, data)
	_expect("a bench never set up makes nothing", still != null and int(still.firearms.bullets) == int(idle.firearms.bullets))
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
