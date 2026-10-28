extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const NeighbourhoodChecks = preload("res://tools/checks/checks_neighbourhood.gd")


static func prepared(id: String = "garden") -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for site: String in ["garden", "library", "garage"]:
		w.claim(site)
	NeighbourhoodChecks.integrate(w)
	w.player.pos = w.routes.point(w.definition(Restoration.target(id)).site)
	if id == "armour":
		# Existing completed fixture; only the next restoration is under test.
		w.workshop.started = true
		w.workshop.done = true
		w.workshop.progress = float(w.balance.workshop_seconds)
	Restoration.approve(w, id)
	w.working = true
	return w


func check_restoration_cancel_returns_exactly_once_and_releases_worker() -> String:
	for id: String in ["garden", "workshop", "armour"]:
		var w: RefCounted = prepared(id)
		w.assign_survivor("mara", Restoration.target(id))
		var recipe: Dictionary = WorkRecipes.recipe(w.catalog, id)
		Restoration.step(w, id, float(recipe.seconds) * 0.5)
		var stock: int = w.materials
		var refund: int = floori(float(recipe.inputs.materials) * 0.875)
		if not Restoration.cancel(w, "restore:" + id) or w.materials != stock + refund or Restoration.cancel(w, "restore:" + id):
			return "Incorrect cancellation return for " + id
		if w.survivors[0].job != "":
			return "Cancelled project retained an invalid worker job."
		var save := SaveState.new(w.catalog)
		if not save.valid(save.snapshot(w)):
			return "Cancelled project is not saveable: " + id
	return ""


func check_restoration_loss_final_tick_and_reload_preserve_commitments() -> String:
	var w: RefCounted = prepared("workshop")
	Restoration.step(w, "workshop", 3.0)
	var stock: int = w.materials
	w.properties.garage.claimed = false
	Restoration.step(w, "workshop", 100.0)
	if w.workshop.progress != 3.0 or w.workshop.done:
		return "Lost restoration completed."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Lost restoration did not reload."
	loaded.claim("garage")
	loaded.working = true
	Restoration.step(loaded, "workshop", float(w.balance.workshop_seconds) - 3.0)
	Restoration.step(loaded, "workshop", 100.0)
	if not loaded.workshop.done or loaded.materials != stock:
		return "Reclaim lost work, repeated completion or charged twice."
	return ""


func check_old_partial_restorations_migrate_without_spending() -> String:
	for id: String in ["garden", "workshop", "armour"]:
		var w: RefCounted = prepared(id)
		Restoration.step(w, id, 2.0)
		var save := SaveState.new(w.catalog)
		var old: Dictionary = save.snapshot(w)
		old.schema_version = 15
		old.orders = WorkOrders.initial()
		var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
		if loaded == null or loaded.materials != w.materials or float(WorkOrders.current(loaded, "restore:" + id).work_done) != 2.0:
			return "Prepaid old restoration migration failed: " + id
	return ""


func check_board_limit_and_invalid_approvals_never_debit() -> String:
	var w: RefCounted = prepared()
	w.catalog.work.pending_limit = 1
	w.player.pos = Vector2(1080, 800)
	var stock: int = w.materials
	if Restoration.approve(w, "workshop") or w.materials != stock:
		return "Full work board accepted/spent on another project."
	w.catalog.work.pending_limit = 8
	w.player.pos = Vector2(360, 350)
	if Restoration.approve(w, "workshop") or w.materials != stock:
		return "Remote approval spent stock."
	w.player.pos = Vector2(1080, 800)
	w.player.hp = 0.0
	if Restoration.approve(w, "workshop") or w.materials != stock:
		return "Downed player approved a new project."
	return ""


func check_recipe_catalog_rejects_unimplemented_or_mistyped_effects() -> String:
	var source: Dictionary = Catalog.read()
	for entry: Array in [["source", "weather"], ["cost", "missing"], ["seconds", "missing"], ["output", "fuel"], ["kind", "research"]]:
		var bad: Dictionary = source.duplicate(true)
		bad.work.recipes[2][entry[0]] = entry[1]
		if Catalog.problems(bad).is_empty():
			return "Accepted invalid work recipe: " + str(entry[0])
	var w: RefCounted = prepared()
	var save := SaveState.new(w.catalog)
	var bad: Dictionary = save.snapshot(w)
	bad.garden_progress = 1.0
	return "Accepted drift from paid garden progress" if save.valid(bad) else ""
