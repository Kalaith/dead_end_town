extends RefCounted
const RepairState = preload("res://scripts/core/repair_state.gd")
const Repairs = preload("res://scripts/sim/repairs.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var policy: Variant = data.get("production")
	if not policy is Dictionary or policy.get("mode") not in ["stopped", "once", "repeat"]:
		return false
	if not Rules.integer_in(policy.get("target"), 0, 999) or not Rules.integer_in(policy.get("material_reserve"), 0, 999) or not policy.get("reason") is String:
		return false
	if policy.mode != "stopped" and not data.properties.munitions.looted:
		return false
	var ledger: Variant = data.get("orders")
	if not ledger is Dictionary or not Rules.integer_in(ledger.get("sequence"), 0, 1000000000) or not ledger.get("sites") is Dictionary:
		return false
	var ids: Array[String] = []
	for socket: Variant in ledger.sites:
		var order: Variant = ledger.sites[socket]
		if not order is Dictionary or not _valid_order(order, catalog) or not _valid_site(order, data, catalog):
			return false
		if int(order.sequence) > int(ledger.sequence) or ids.has(order.id) or order.socket != socket:
			return false
		ids.append(order.id)
	for id: String in data.passages:
		var state: Dictionary = data.passages[id]
		if state.started and not state.done and not ledger.sites.has("passage:" + id):
			return false
	for id: String in data.roadworks:
		if data.roadworks[id].phase in ["building", "dismantling"] and not ledger.sites.has("road:" + id):
			return false
	for id: String in ["garden", "workshop", "armour", "clinic"]:
		var flags: Array = _restoration(data, id)
		if flags[0] and not flags[1] and not ledger.sites.has("restore:" + id):
			return false
	return RepairState.valid(data)


static func _restoration(data: Dictionary, id: String) -> Array:
	if id == "garden":
		return [data.garden_started, data.garden_done, data.garden_progress]
	if id == "clinic":
		return [data.clinic.started, data.clinic.done, data.clinic.progress]
	if id == "workshop":
		return [data.workshop.started, data.workshop.done, data.workshop.progress]
	return [data.workshop.armour_started, data.workshop.armour_done, data.workshop.armour_progress]


static func _valid_site(o: Dictionary, data: Dictionary, catalog: Dictionary) -> bool:
	if o.recipe in Repairs.IDS:
		return RepairState.valid_site(o, data, catalog)
	if o.recipe in ["road_build", "road_remove"]:
		if o.socket != "road:" + str(o.target) or not data.roadworks.has(o.target):
			return false
		var state: Dictionary = data.roadworks[o.target]
		if o.phase in ["approved", "working", "blocked"]:
			return state.phase == ("building" if o.recipe == "road_build" else "dismantling") and float(state.progress) == float(o.work_done)
		if o.phase == "destroyed":
			return state.phase == "empty"
		if o.phase == "completed":
			return state.phase == ("ready" if o.recipe == "road_build" else "empty")
		return state.phase == ("empty" if o.recipe == "road_build" else "ready")
	if o.recipe in ["garden", "workshop", "armour", "clinic"]:
		var flags: Array = _restoration(data, o.recipe)
		if o.socket != "restore:" + str(o.recipe) or o.target != ("clinic" if o.recipe == "clinic" else "garden" if o.recipe == "garden" else "garage"):
			return false
		if o.phase in ["approved", "working", "blocked"]:
			return flags[0] and not flags[1] and float(flags[2]) == float(o.work_done)
		if o.phase == "completed":
			return flags[1]
		return not flags[0] and not flags[1]
	if o.recipe == "bullets":
		return o.socket == "munitions" and o.target == "munitions" and data.properties.munitions.looted
	for d: Dictionary in catalog.passages:
		if o.socket != "passage:" + str(d.id) or o.target != d.id:
			continue
		var state: Dictionary = data.passages[d.id]
		if o.phase in ["approved", "working", "blocked"]:
			if not state.started or state.done or float(state.progress) != float(o.work_done):
				return false
		elif o.phase == "completed":
			if not state.done:
				return false
		elif state.started:
			return false
		return true
	return false


static func _valid_order(o: Dictionary, catalog: Dictionary) -> bool:
	if not Rules.integer_in(o.get("sequence"), 1, 1000000000) or o.get("id") != "work_%d" % int(o.sequence):
		return false
	if o.get("recipe") not in WorkRecipes.IDS:
		return false
	var recipe: Dictionary = WorkRecipes.recipe(catalog, o.recipe)
	if o.get("kind") != recipe.kind:
		return false
	if o.get("phase") not in ["approved", "working", "blocked", "completed", "cancelled", "destroyed"]:
		return false
	if not _bundle(o.get("inputs"), "materials", int(recipe.inputs.materials)):
		return false
	if not o.get("outputs") is Dictionary:
		return false
	if not recipe.outputs.is_empty() and not _bundle(o.outputs, "bullets", int(recipe.outputs.bullets)):
		return false
	if recipe.outputs.is_empty() and not o.outputs.is_empty():
		return false
	if not Rules.finite(o.get("work_required")) or float(o.work_required) != float(recipe.seconds):
		return false
	if not Rules.finite(o.get("work_done")) or float(o.work_done) < 0 or float(o.work_done) > float(o.work_required):
		return false
	if not o.get("executor") is String or not o.get("blocked_reason") is String or not Rules.is_vec2(o.get("stand")):
		return false
	if not o.get("priority") is bool or not o.get("output_granted") is bool or not o.get("salvage_paid") is bool:
		return false
	if o.output_granted != (o.phase == "completed") or o.salvage_paid != (o.phase == "cancelled"):
		return false
	if o.phase == "completed" and float(o.work_done) != float(o.work_required):
		return false
	if o.phase == "blocked" and o.blocked_reason.is_empty():
		return false
	return true


static func _bundle(value: Variant, key: String, count: int) -> bool:
	return value is Dictionary and value.size() == 1 and Rules.integer_in(value.get(key), count, count)
