extends VBoxContainer
const Equipment = preload("res://scripts/sim/equipment.gd")
signal chosen(actor_id: String, slot: String, item_id: String)
var rows: Dictionary = {}


func _ready() -> void:
	var help := Label.new()
	help.text = "LOADOUTS / Change gear together at the connected workshop\nBat: quick single hit. Crowbar: slow, strong hit. Sword: two targets.\nIron: half damage, slower movement. Shield: protects the front. Return unique gear before transferring."
	help.add_theme_font_size_override("font_size", 13)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)


func refresh(world: RefCounted) -> void:
	visible = world.workshop.done
	if not visible:
		return
	for a: Dictionary in [world.player] + world.survivors:
		if not rows.has(a.id):
			_create(a.id)
		var row: Dictionary = rows[a.id]
		var reason: String = Equipment.reason(world, a.id)
		row.label.text = "%s / %s" % [a.name, Equipment.description(world, a)]
		row.label.tooltip_text = reason
		for slot: String in ["weapon", "protection", "shield"]:
			var picker: OptionButton = row[slot]
			var signature: String = JSON.stringify([world.equipment, world.workshop.armour_done, world.properties.garage.looted, reason])
			if picker.get_meta("signature", "") == signature:
				continue
			picker.set_meta("signature", signature)
			picker.clear()
			picker.disabled = not reason.is_empty() or (a.id == "ellis" and slot == "weapon")
			picker.tooltip_text = reason if not reason.is_empty() else "Change " + slot + " at the bench"
			var ids: Array = ["bat", "crowbar", "sword"] if slot == "weapon" else (["none", "iron"] if slot == "protection" else ["none", "shield"])
			for id: String in ids:
				if not Equipment.unlocked(world, id):
					continue
				var label: String = "No " + slot if id == "none" else (world.catalog.equipment.weapons[id].name if slot == "weapon" else id.capitalize())
				var owner: String = str(world.equipment.get(id, ""))
				if not owner.is_empty() and owner != a.id:
					label += " (in use)"
				var index: int = picker.item_count
				picker.add_item(label)
				picker.set_item_metadata(index, id)
				picker.set_item_disabled(index, not owner.is_empty() and owner != a.id)
				if (slot == "weapon" and Equipment.weapon(world, a) == id) or (slot != "weapon" and ((id == "none" and not world.equipment.values().has(a.id)) or owner == a.id)):
					picker.select(index)
			if slot != "weapon":
				var gear: String = "iron" if slot == "protection" else "shield"
				picker.select(1 if Equipment.unlocked(world, gear) and world.equipment[gear] == a.id else 0)
	for id: String in rows.keys():
		if Equipment.person(world, id).is_empty():
			rows[id].box.queue_free()
			rows.erase(id)


func _create(id: String) -> void:
	var box := VBoxContainer.new()
	add_child(box)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 14)
	box.add_child(label)
	var line := HBoxContainer.new()
	box.add_child(line)
	var row: Dictionary = {"box": box, "label": label}
	for slot: String in ["weapon", "protection", "shield"]:
		var picker := OptionButton.new()
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.custom_minimum_size = Vector2(200, 36)
		picker.fit_to_longest_item = false
		line.add_child(picker)
		picker.item_selected.connect(func(index: int) -> void: chosen.emit(id, slot, str(picker.get_item_metadata(index))))
		row[slot] = picker
	rows[id] = row
