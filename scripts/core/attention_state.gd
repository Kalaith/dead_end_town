extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "attention")
	if not rules.object(data, "attention"):
		return
	rules.number_between(data.attention, "memory_seconds", 0.1, 30)
	if not rules.object(data.attention, "events"):
		return
	for key: String in ["impact", "work", "pistol", "screecher", "engine"]:
		if not rules.object(data.attention.events, key):
			continue
		for field: String in ["radius", "lifetime", "refresh"]:
			rules.number_between(data.attention.events[key], field, 0.01, 1000)


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("noise") is Dictionary or not data.get("memories") is Dictionary:
		return false
	var state: Dictionary = data.noise
	if not Rules.integer_in(state.get("sequence"), 0, 1000000000) or not state.get("events") is Array or state.events.size() > 256:
		return false
	var keys: Array[String] = []
	var ids: Array[int] = []
	for raw: Variant in state.events:
		if not raw is Dictionary:
			return false
		var event: Dictionary = raw
		if not Rules.nonempty(event.get("emitter")) or not event.get("category") is String or not catalog.attention.events.has(event.category):
			return false
		if not Rules.integer_in(event.get("id"), 1, int(state.sequence)) or int(event.id) in ids or event.get("key") != event.category + ":" + event.emitter or event.key in keys:
			return false
		ids.append(int(event.id))
		keys.append(event.key)
		if not _point(event, catalog):
			return false
		var config: Dictionary = catalog.attention.events[event.category]
		if not Rules.finite(event.get("radius")) or float(event.radius) != float(config.radius) or not Rules.finite(event.get("updated")) or float(event.updated) < 0 or float(event.updated) > float(data.elapsed):
			return false
		if not Rules.finite(event.get("expires")) or absf(float(event.expires) - float(event.updated) - float(config.lifetime)) > 0.001 or float(event.expires) <= float(data.elapsed):
			return false
	var known: Array[String] = []
	for z: Dictionary in data.zombies:
		known.append(z.id)
	for id: String in data.memories:
		var memory: Variant = data.memories[id]
		if id not in known or not memory is Dictionary or not _point(memory, catalog):
			return false
		if not Rules.finite(memory.get("expires")) or float(memory.expires) <= float(data.elapsed) or float(memory.expires) > float(data.elapsed) + float(catalog.attention.memory_seconds) + 0.001:
			return false
	return true


static func _point(value: Dictionary, catalog: Dictionary) -> bool:
	return Rules.finite(value.get("x")) and Rules.finite(value.get("y")) and float(value.x) >= 0 and float(value.y) >= 0 and float(value.x) <= float(catalog.bounds[0]) and float(value.y) <= float(catalog.bounds[1])
