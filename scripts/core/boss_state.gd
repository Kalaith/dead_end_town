extends RefCounted
## Boss content and save checks. An area either has both a boss and an exit, or neither.
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Boss = preload("res://scripts/sim/boss.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if data.has("boss") != data.has("exit"):
		errors.append("An area needs a boss and an exit together.")
		return
	if not data.has("boss"):
		return
	var rules := Rules.new(errors, "boss")
	if not rules.object(data, "boss") or not rules.object(data, "exit"):
		return
	rules.text(data.boss, "id")
	rules.text(data.boss, "kind")
	rules.vec2(data.boss, "post")
	rules.number_between(data.boss, "leash", 30.0, 2000.0)
	rules.text(data.exit, "name")
	if data.get("balance") is Dictionary:
		rules.number_between(data.balance, "area_carry_cap", 1, 10000)
	if not data.exit.get("rect") is Array or data.exit.rect.size() != 4:
		errors.append("Exit needs a four-number rectangle.")
	if not data.boss.get("escorts") is Array:
		errors.append("Boss needs an escort list.")
	else:
		for pos: Variant in data.boss.escorts:
			if not Rules.is_vec2(pos):
				errors.append("Invalid escort position.")
	if data.boss.get("kind") is String and not data.get("zombies", {}).get("types", {}).has(data.boss.kind):
		errors.append("Boss kind is not a zombie type.")


## Every boss and escort is present, belongs to the boss and keeps its kind.
static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var found: Dictionary = {}
	for z: Variant in data.zombies:
		if z.get("home") == Boss.HOME:
			found[z.id] = z
	var ids: Array[String] = Boss.resident_ids(catalog)
	if found.size() != ids.size():
		return false
	for id: String in ids:
		if not found.has(id) or bool(found[id].raid):
			return false
	return found.is_empty() or found[catalog.boss.id].get("kind") == catalog.boss.kind
