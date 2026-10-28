extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "equipment")
	if data.get("balance") is Dictionary:
		rules.number_between(data.balance, "equipment_range", 30, 200)
	if not rules.object(data, "equipment") or not rules.object(data.equipment, "weapons"):
		return
	var weapons: Dictionary = data.equipment.weapons
	if weapons.keys() != ["bat", "crowbar", "sword", "spear"]:
		errors.append("Equipment needs exactly the implemented bat, crowbar, sword and spear.")
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
	if not data.get("equipment") is Dictionary or data.equipment.size() != 5:
		return false
	var wearers: Array[String] = ["", "you"]
	for a: Dictionary in data.survivors:
		wearers.append(a.id)
	for id: String in ["crowbar", "sword", "iron", "shield", "spear"]:
		if not data.equipment.get(id) is String or not wearers.has(data.equipment[id]):
			return false
		if not data.equipment[id].is_empty() and not (data.properties.hardware.looted if id == "spear" else data.properties.garage.looted if id == "crowbar" else data.workshop.armour_done):
			return false
	var weapons: Array[String] = []
	for id: String in ["crowbar", "sword", "spear"]:
		if not data.equipment[id].is_empty():
			if data.equipment[id] == "ellis" or data.equipment[id] in weapons:
				return false
			weapons.append(data.equipment[id])
	if not data.equipment.spear.is_empty() and data.equipment.spear == data.equipment.shield:
		return false
	return data.workshop.equipped == (data.equipment.iron == "paige" and data.equipment.shield == "paige")
