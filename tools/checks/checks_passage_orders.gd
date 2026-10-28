extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")


static func prepared() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	w.claim("garden")
	w.player.pos = Vector2(600, 400)
	w.interact()
	w.working = true
	return w


func check_passage_ledger_handoff_loss_and_json_reload_preserve_paid_work() -> String:
	var w: RefCounted = prepared()
	Neighbourhood.step(w, 1.0)
	w.working = false
	w.assign_survivor("mara", "passage:north")
	w.survivors[0].pos = Vector2(600, 400)
	Neighbourhood.step(w, 1.0)
	var stock: int = w.materials
	w.properties.garden.claimed = false
	Neighbourhood.step(w, 8.0)
	var order: Dictionary = WorkOrders.current(w, "passage:north")
	if float(order.work_done) != 2.0 or order.blocked_reason != "Reclaim site" or order.executor != "":
		return "Lost site progressed or retained its lease."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Blocked paid passage did not reload."
	loaded.claim("garden")
	loaded.working = true
	Neighbourhood.step(loaded, float(w.balance.passage_seconds) - 2.0)
	if not loaded.passages.north.done or loaded.materials != stock:
		return "Reclaim/player takeover lost work or charged again."
	return ""


func check_downed_person_blocks_final_collision_until_work_area_is_clear() -> String:
	var w: RefCounted = prepared()
	w.survivors[0].hp = 0.0
	w.survivors[0].pos = Vector2(720, 400)
	Neighbourhood.step(w, float(w.balance.passage_seconds))
	var order: Dictionary = WorkOrders.current(w, "passage:north")
	if w.passages.north.done or order.phase != "blocked" or order.blocked_reason != "Clear work area":
		return "Passage appeared through a downed person."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Final-tick footprint block failed to reload."
	loaded.survivors[0].pos = Vector2(360, 350)
	loaded.working = true
	Neighbourhood.step(loaded, 0.05)
	return "Cleared work area did not release completion" if not loaded.passages.north.done else ""


func check_passage_cancel_uses_construction_refund_and_is_once_only() -> String:
	var w: RefCounted = prepared()
	var stock: int = w.materials
	Neighbourhood.step(w, float(w.balance.passage_seconds) / 2.0)
	var expected: int = floori(float(w.balance.passage_cost) * 0.875)
	if int(WorkOrders.refund(WorkOrders.current(w, "passage:north")).materials) != expected:
		return "Construction refund consumes too much or too little."
	if not Neighbourhood.cancel(w, "passage:north") or w.materials != stock + expected or Neighbourhood.cancel(w, "passage:north"):
		return "Cancelled passage refunded incorrectly or twice."
	var save := SaveState.new(w.catalog)
	return "Cancelled projection is not saveable" if not save.valid(save.snapshot(w)) or w.passages.north.started else ""


func check_two_passages_have_independent_bundles_and_one_rate_per_socket() -> String:
	var w: RefCounted = prepared()
	w.claim("library")
	w.claim("garage")
	w.player.pos = Vector2(600, 760)
	w.interact()
	w.assign_survivor("mara", "passage:south")
	w.survivors[0].pos = Vector2(600, 760)
	w.assign_survivor("paige", "passage:south")
	w.survivors[1].pos = Vector2(600, 760)
	w.player.pos = Vector2(600, 400)
	Neighbourhood.step(w, 1.0)
	if float(w.passages.north.progress) != 1 or float(w.passages.south.progress) != 1:
		return "Multiple workers doubled a site or blocked a concurrent site."
	return ""


func check_schema_fourteen_passage_migrates_without_rebilling_and_drift_is_rejected() -> String:
	var w: RefCounted = prepared()
	Neighbourhood.step(w, 2.0)
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 14
	old.orders = WorkOrders.initial()
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.materials != w.materials or float(WorkOrders.current(loaded, "passage:north").work_done) != 2:
		return "Legacy partial passage lost work or was rebilled."
	var bad: Dictionary = save.snapshot(loaded)
	bad.passages.north.progress = 3.0
	if save.valid(bad):
		return "Accepted drift between ledger and passage projection."
	bad = save.snapshot(loaded)
	bad.orders.sites.erase("passage:north")
	return "Accepted missing paid order" if save.valid(bad) else ""
