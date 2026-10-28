extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const IDS: Array[String] = ["bullets", "passage", "garden", "workshop", "armour", "road_build", "road_remove", "repair_line", "gate_rebuild", "legacy_repair", "clinic", "medicine"]


static func definition(catalog: Dictionary, id: String) -> Dictionary:
	for entry: Dictionary in catalog.work.recipes:
		if entry.id == id:
			return entry
	return {}


static func recipe(catalog: Dictionary, id: String) -> Dictionary:
	var entry: Dictionary = definition(catalog, id)
	var source: Dictionary = catalog[entry.source]
	var outputs: Dictionary = {}
	if not str(entry.output).is_empty():
		outputs[entry.output] = int(source[entry.count])
	var inputs: Dictionary = {"materials": int(source[entry.cost])}
	if id == "medicine":
		inputs.food = int(source[entry.food_cost])
	return {"id": id, "kind": entry.kind, "inputs": inputs, "outputs": outputs, "seconds": float(source[entry.seconds])}


static func content(catalog: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "work recipes")
	if not rules.object(catalog, "work"):
		return
	if not Rules.integer_in(catalog.work.get("pending_limit"), 1, 32):
		errors.append("Work needs a bounded pending-project limit.")
	if not rules.list(catalog.work, "recipes", false):
		return
	if rules.unique_ids(catalog.work.recipes) != IDS:
		errors.append("Work recipe IDs must match implemented recipes in order.")
	for raw: Variant in catalog.work.recipes:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		rules.text(entry, "name")
		if entry.get("source") not in ["balance", "firearm"] or entry.get("kind") not in ["construction", "production", "repair"]:
			errors.append("Invalid work recipe source/kind.")
			continue
		if not catalog.get(entry.source) is Dictionary:
			errors.append("Missing recipe balance source.")
			continue
		var source: Dictionary = catalog[entry.source]
		if not entry.get("cost") is String or not Rules.integer_in(source.get(entry.get("cost", "")), 0, 10000):
			errors.append("Recipe needs a whole implemented material cost.")
		if not entry.get("seconds") is String or not Rules.finite(source.get(entry.get("seconds", ""))) or float(source.get(entry.get("seconds", ""), 0)) <= 0:
			errors.append("Recipe needs positive implemented work seconds.")
		if entry.get("id") == "bullets":
			if entry.source != "firearm" or entry.kind != "production" or entry.get("output") != "bullets" or entry.get("count") != "batch_bullets":
				errors.append("Bullet recipe must produce the implemented bullet batch.")
		elif entry.get("id") == "medicine":
			if entry.source != "balance" or entry.kind != "production" or entry.get("output") != "medicine" or entry.get("count") != "medicine_batch" or entry.get("food_cost") != "medicine_food_cost" or not Rules.integer_in(source.get("medicine_food_cost"), 1, 1000):
				errors.append("Medicine must use the implemented material/food batch.")
		elif entry.get("output") != "" or entry.get("count") != "" or entry.kind != ("repair" if entry.id in ["repair_line", "legacy_repair"] else "construction") or entry.source != "balance":
			errors.append("Construction cannot invent resource outputs.")
