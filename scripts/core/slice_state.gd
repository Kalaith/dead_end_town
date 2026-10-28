extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "slice objective")
	if data.get("balance") is Dictionary and not Rules.integer_in(data.balance.get("timber_materials"), 1, 1000):
		errors.append("Timber salvage must yield bounded whole materials.")
	if not rules.object(data, "slice"):
		return
	for key: String in ["hold_seconds", "harvest_food", "start_range"]:
		rules.number_between(data.slice, key, 1, 1000)
	if not Rules.whole(data.slice.get("harvest_food")):
		errors.append("Slice harvest goal must be whole food portions.")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("timber") is Dictionary or data.timber.size() != 3:
		return false
	for id: String in ["garden", "library", "garage"]:
		if not data.timber.get(id) is bool or (data.timber[id] and not data.properties[id].looted):
			return false
	if not data.get("slice_state") is Dictionary:
		return false
	var s: Dictionary = data.slice_state
	if s.get("phase") not in ["preparing", "watch", "complete"] or not s.get("blocked") is String or not Rules.finite(s.get("held")):
		return false
	if not Rules.integer_in(s.get("downs"), 0, 1000000000) or int(s.downs) > int(data.downs):
		return false
	if float(s.held) < 0 or float(s.held) > float(catalog.slice.hold_seconds):
		return false
	if s.phase == "preparing" and (float(s.held) != 0 or not s.blocked.is_empty()):
		return false
	if s.phase == "complete" and (float(s.held) != float(catalog.slice.hold_seconds) or not s.blocked.is_empty()):
		return false
	return s.blocked.is_empty() or float(s.held) == 0
