extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Facility = preload("res://scripts/sim/facility.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "slice objective")
	if data.get("balance") is Dictionary and not Rules.integer_in(data.balance.get("timber_materials"), 1, 1000):
		errors.append("Timber salvage must yield bounded whole materials.")
	if not rules.object(data, "slice"):
		return
	for key: String in ["harvest_food", "start_range"]:
		rules.number_between(data.slice, key, 1, 1000)
	if not Rules.whole(data.slice.get("harvest_food")):
		errors.append("Slice harvest goal must be whole food portions.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("timber") is Dictionary or data.timber.size() != 3:
		return false
	for id: String in ["garden", "library", "garage"]:
		if not data.timber.get(id) is bool or (data.timber[id] and not Facility.saved(data, catalog, id).looted):
			return false
	return true
