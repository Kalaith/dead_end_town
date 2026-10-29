extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Tips = preload("res://scripts/sim/tips.gd")


## Every tip the rules can raise needs authored text, and no text may be left without a rule.
static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "Tips")
	if not rules.object(data, "tips"):
		return
	for id: String in Tips.ORDER:
		if not data.tips.get(id) is String or str(data.tips[id]).strip_edges().is_empty():
			errors.append("Tip %s needs text." % id)
	for id: String in data.tips:
		if id not in Tips.ORDER:
			errors.append("Tip %s has no rule." % id)
