extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Repairs = preload("res://scripts/sim/repairs.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const NeighbourhoodChecks = preload("res://tools/checks/checks_neighbourhood.gd")


static func prepared() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		w.claim(id)
	NeighbourhoodChecks.integrate(w)
	w.player.pos = Vector2(592, 580)
	w.working = true
	return w


func check_repair_batch_is_bounded_and_unused_capacity_cannot_be_banked() -> String:
	var w: RefCounted = prepared()
	w.roadworks.home_east.hp = 20.0
	var stock: int = w.materials
	Repairs.step(w, "road:home_east", "you", 5.0)
	if w.roadworks.home_east.hp != 140.0 or w.materials != stock - 3 or w.roadworks.home_east.repair_reserved:
		return "One batch exceeded 120 health or retained unused credit."
	w.roadworks.home_east.hp = 179.0
	Repairs.step(w, "road:home_east", "you", 0.05)
	if w.materials != stock - 6 or w.roadworks.home_east.repair_reserved:
		return "Reaching full health failed to discard remaining capacity."
	w.roadworks.home_east.hp = 170.0
	Repairs.step(w, "road:home_east", "you", 0.5)
	return "Old capacity healed later damage for free" if w.materials != stock - 9 or w.roadworks.home_east.hp != 180.0 else ""


func check_partial_repair_loss_reload_and_reclaim_preserve_capacity() -> String:
	var w: RefCounted = prepared()
	w.roadworks.home_east.hp = 30.0
	Repairs.step(w, "road:home_east", "you", 2.0)
	var stock: int = w.materials
	w.properties.library.claimed = false
	Repairs.step(w, "road:home_east", "you", 5.0)
	if w.roadworks.home_east.hp != 78.0:
		return "Lost site still repaired."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Partial bounded repair failed to reload."
	loaded.claim("library")
	loaded.working = true
	Repairs.step(loaded, "road:home_east", "you", 3.0)
	return "Loaded repair lost capacity or charged again" if loaded.materials != stock or loaded.roadworks.home_east.hp != 150.0 else ""


func check_broken_gate_rebuild_has_no_partial_protection_and_finishes_open() -> String:
	var w: RefCounted = prepared()
	w.properties.home.gate_hp = 0.0
	w.properties.home.open = false
	w.player.pos = Vector2(360, 440)
	w.rebuild_routes()
	Repairs.step(w, "gate:home", "you", 3.0)
	if w.properties.home.gate_hp != 0.0 or not w.routes.walkable(Vector2(360, 480)):
		return "Unfinished rebuild created protection/collision."
	var stock: int = w.materials
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Gate rebuild did not reload."
	loaded.working = true
	Repairs.step(loaded, "gate:home", "you", 4.0)
	return "Rebuild rebilled or closed through its repairer" if loaded.materials != stock or loaded.properties.home.gate_hp != 160.0 or not loaded.properties.home.open else ""


func check_ai_repair_respects_reserve_and_defended_critical_line_exception() -> String:
	var w: RefCounted = prepared()
	w.working = false
	w.assign_survivor("mara", "work:home_east")
	# Make assignment available before applying the tested damage.
	w.roadworks.home_east.hp = 150.0
	w.assign_survivor("mara", "work:home_east")
	w.survivors[0].pos = Vector2(592, 580)
	w.materials = 7
	Repairs.step(w, "road:home_east", "mara", 1.0)
	if w.materials != 7 or w.roadworks.home_east.hp != 150.0:
		return "AI spent protected materials on routine repair."
	w.roadworks.home_east.hp = 50.0
	var defender: Dictionary = w.survivors[1]
	defender.order = "Roadguard"
	defender.anchor = Roadworks.guard_post(w, w.catalog.barricades[1])
	defender.pos = defender.anchor
	Repairs.step(w, "road:home_east", "mara", 1.0)
	return "Defended critical repair failed to use its explicit exception" if w.materials != 4 or w.roadworks.home_east.hp != 74.0 else ""


func check_removal_destroys_attached_repair_without_an_extra_refund() -> String:
	var w: RefCounted = prepared()
	w.roadworks.home_east.hp = 90.0
	Repairs.step(w, "road:home_east", "you", 1.0)
	var stock: int = w.materials
	w.interact()
	if w.materials != stock or w.roadworks.home_east.repair_reserved or WorkOrders.current(w, "repair:road:home_east").phase != "destroyed":
		return "Removal paid an extra repair refund."
	var save := SaveState.new(w.catalog)
	return "Removal/attached repair is not saveable" if not save.valid(save.snapshot(w)) else ""


func check_old_prepaid_full_gap_remains_paid_and_repair_flags_are_validated() -> String:
	var w: RefCounted = prepared()
	w.player.pos = Vector2(360, 440)
	w.properties.home.gate_hp = 1.2
	w.repair_reserved = true
	w.gate_repair_target = "home"
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 17
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null:
		return "Legacy paid full-gap repair did not migrate."
	loaded.working = true
	Repairs.step(loaded, "gate:home", "you", 7.0)
	if loaded.materials != w.materials or loaded.properties.home.gate_hp != 160.0:
		return "Legacy full gap was cut to 120 health or billed again."
	var raw: Dictionary = save.snapshot(loaded)
	raw.repair_reserved = true
	return "Accepted reservation without a paid repair" if save.valid(raw) else ""


func check_downed_people_block_closing_property_and_passage_gates() -> String:
	var w: RefCounted = prepared()
	w.survivors[0].hp = 0.0
	w.survivors[0].pos = Vector2(360, 480)
	w.player.pos = Vector2(360, 440)
	w.properties.home.open = true
	w.interact()
	if not w.properties.home.open:
		return "Closed a yard gate through a downed person."
	w.survivors[0].pos = Vector2(720, 400)
	w.player.pos = Vector2(600, 400)
	w.passages.north.open = true
	w.interact()
	return "Closed a passage through a downed person" if not w.passages.north.open else ""
