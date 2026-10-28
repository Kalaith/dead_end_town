extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "equipment")
	if data.get("balance") is Dictionary:
		rules.number_between(data.balance, "equipment_range", 30, 200)
	if not rules.object(data, "equipment") or not rules.object(data.equipment, "weapons"):
		return
	var weapons: Dictionary = data.equipment.weapons
	if weapons.keys() != ["bat", "crowbar", "sword"]:
		errors.append("Equipment needs exactly the implemented bat, crowbar and sword.")
	for raw: Variant in weapons.values():
		if not raw is Dictionary:
			errors.append("Weapon must be an object.")
			continue
		var w: Dictionary = raw
		rules.text(w, "name")
		for key: String in ["damage", "reach", "cooldown", "knockback"]:
			rules.number_between(w, key, 0.01, 200)
		rules.number_between(w, "cone", -1, 0.99)
		if not Rules.integer_in(w.get("targets"), 1, 2):
			errors.append("Weapons support one or two targets.")


static func valid(data: Dictionary) -> bool:
	if not data.get("equipment") is Dictionary or data.equipment.size() != 4:
		return false
	var wearers: Array[String] = ["", "you", "mara"]
	if data.properties.library.looted:
		wearers.append("paige")
	if data.properties.residence.looted:
		wearers.append("ellis")
	for id: String in ["crowbar", "sword", "iron", "shield"]:
		if not data.equipment.get(id) is String or not wearers.has(data.equipment[id]):
			return false
		if not data.equipment[id].is_empty() and not (data.properties.garage.looted if id == "crowbar" else data.workshop.armour_done):
			return false
	if not data.equipment.crowbar.is_empty() and data.equipment.crowbar == data.equipment.sword:
		return false
	return data.workshop.equipped == (data.equipment.iron == "paige" and data.equipment.shield == "paige")
