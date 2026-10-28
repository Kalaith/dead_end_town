extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")


static func prepared() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("library")
	w.player.pos = Vector2(592, 580)
	w.interact()
	w.working = true
	return w


func check_road_build_blocks_downed_people_and_keeps_the_bundle_on_loss() -> String:
	var w: RefCounted = prepared()
	w.survivors[0].hp = 0.0
	w.survivors[0].pos = Vector2(640, 580)
	Roadworks.step(w, 8.0)
	var order: Dictionary = WorkOrders.current(w, "road:home_east")
	if w.roadworks.home_east.phase != "building" or order.blocked_reason != "Clear work area":
		return "Barricade trapped a downed survivor."
	var stock: int = w.materials
	w.survivors[0].pos = Vector2(360, 350)
	w.properties.library.claimed = false
	Roadworks.step(w, 2.0)
	if w.roadworks.home_east.phase != "building" or order.blocked_reason != "Reclaim site":
		return "Lost site completed its barricade."
	w.claim("library")
	Roadworks.step(w, 0.05)
	return "Resumed barricade charged again" if w.materials != stock or w.roadworks.home_east.phase != "ready" else ""


func check_removal_reload_uses_current_damage_and_pays_salvage_once() -> String:
	var w: RefCounted = prepared()
	Roadworks.step(w, 8.0)
	w.interact()
	Roadworks.step(w, 2.0)
	w.working = false
	w.roadworks.home_east.hp = 90.0
	var stock: int = w.materials
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.routes.walkable(Vector2(640, 580)):
		return "Half removal lost collision or failed to reload."
	loaded.working = true
	Roadworks.step(loaded, 2.0)
	Roadworks.step(loaded, 2.0)
	if loaded.materials != stock + 3 or loaded.roadworks.home_east.phase != "empty" or not loaded.routes.walkable(Vector2(640, 580)):
		return "Damaged removal paid twice or ignored its damage."
	return ""


func check_cancelled_removal_then_breach_never_pays_and_stays_saveable() -> String:
	var w: RefCounted = prepared()
	Roadworks.step(w, 8.0)
	w.interact()
	Roadworks.step(w, 2.0)
	var stock: int = w.materials
	if not Roadworks.cancel(w, "road:home_east") or w.materials != stock:
		return "Keeping a barrier paid salvage."
	var z: Dictionary = w.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(665, 580)
	z.cooldown = 0.0
	w.roadworks.home_east.hp = 1.0
	Roadworks.intercept(w, z, Vector2(600, 580), 0.05)
	var save := SaveState.new(w.catalog)
	if w.roadworks.home_east.phase != "empty" or w.materials != stock or not save.valid(save.snapshot(w)):
		return "Breach after keeping a barrier paid salvage or corrupted the order."
	return ""


func check_schema_sixteen_road_work_migrates_without_changing_stock() -> String:
	for removal: bool in [false, true]:
		var w: RefCounted = prepared()
		if removal:
			Roadworks.step(w, 8.0)
			w.interact()
		Roadworks.step(w, 1.0)
		var save := SaveState.new(w.catalog)
		var old: Dictionary = save.snapshot(w)
		old.schema_version = 16
		old.orders = WorkOrders.initial()
		var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
		if loaded == null or loaded.materials != w.materials or float(WorkOrders.current(loaded, "road:home_east").work_done) != 1.0:
			return "Legacy road order lost progress or was rebilled."
	return ""
