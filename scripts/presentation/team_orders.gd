extends VBoxContainer
## Compact paused orders: one choice per survivor, no live management panel.
const Equipment = preload("res://scripts/sim/equipment.gd")
const Tasks = preload("res://scripts/sim/tasks.gd")
signal assigned(survivor_id: String, task: String)
var rows: Dictionary = {}
var option_signature: String = ""


func refresh(world: RefCounted) -> void:
	var choices: Array[Dictionary] = Tasks.options(world)
	var signature: String = JSON.stringify(choices)
	var changed: bool = signature != option_signature
	option_signature = signature
	for a: Dictionary in world.survivors:
		var fresh: bool = not rows.has(a.id)
		if fresh:
			_create_row(a.id)
		var row: Dictionary = rows[a.id]
		var equipment: String = Equipment.description(world, a)
		row.status.text = "%s / %d health / %s\n%s" % [a.name, int(a.hp), equipment, a.activity]
		var picker: OptionButton = row.picker
		picker.disabled = float(a.hp) <= 0
		if fresh or changed:
			picker.clear()
			for entry: Dictionary in choices:
				var index: int = picker.item_count
				picker.add_item(entry.label)
				picker.set_item_metadata(index, entry.id)
				picker.set_item_disabled(index, not entry.reason.is_empty())
				picker.get_popup().set_item_tooltip(index, entry.reason)
		var current: String = Tasks.selected(world, a)
		for index: int in range(picker.item_count):
			if picker.get_item_metadata(index) == current:
				picker.select(index)
		picker.tooltip_text = "Choose an assignment for " + a.name
	# New streets and loads can remove Paige without reopening the HUD.
	for id: String in rows.keys():
		if Tasks.person(world, id).is_empty():
			remove_child(rows[id].container)
			rows[id].container.queue_free()
			rows.erase(id)


func _create_row(id: String) -> void:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 12)
	add_child(container)
	var status := Label.new()
	status.custom_minimum_size = Vector2(400, 48)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_theme_font_size_override("font_size", 14)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(status)
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(380, 42)
	picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	picker.fit_to_longest_item = false
	container.add_child(picker)
	picker.item_selected.connect(func(index: int) -> void: assigned.emit(id, str(picker.get_item_metadata(index))))
	rows[id] = {"container": container, "status": status, "picker": picker}


func focus_orders() -> void:
	for row: Dictionary in rows.values():
		if not row.picker.disabled:
			row.picker.grab_focus()
			return
