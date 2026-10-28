extends VBoxContainer
const Jobs = preload("res://scripts/sim/jobs.gd")
signal located(socket: String)
signal assigned(socket: String, id: String)
const Repairs = preload("res://scripts/sim/repairs.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const WorkRecipes = preload("res://scripts/sim/work_recipes.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
signal prioritised(socket: String, value: bool)
signal cancelled(socket: String)
var rows: Dictionary = {}


static func available(world: RefCounted) -> bool:
	for order: Dictionary in world.orders.sites.values():
		if order.kind != "production" and WorkOrders.pending(order):
			return true
	return false


func refresh(world: RefCounted) -> void:
	var active: Array[String] = []
	for socket: String in world.orders.sites:
		var order: Dictionary = world.orders.sites[socket]
		if order.kind == "production" or not WorkOrders.pending(order):
			continue
		active.append(socket)
		if not rows.has(socket):
			_create(socket)
		var row: Dictionary = rows[socket]
		row.priority.set_pressed_no_signal(bool(order.priority))
		_workers(world, socket, row.picker)
		var title: String = WorkRecipes.definition(world.catalog, order.recipe).name
		if order.recipe in Repairs.IDS:
			title += " · " + str(Repairs.describe(world.catalog, order.target).name)
		for d: Dictionary in world.catalog.passages:
			if d.id == order.target:
				title = d.name
		for d: Dictionary in world.catalog.barricades:
			if d.id == order.target:
				title = ("Remove · " if order.recipe == "road_remove" else "") + str(d.name)
		row.label.text = "%s · %d%% · %d materials committed" % [title, int(100 * float(order.work_done) / float(order.work_required)), int(order.inputs.materials)]
		if order.kind == "repair":
			row.label.text = "%s · %d health left · %d materials committed" % [title, ceili((float(order.work_required) - float(order.work_done)) * float(world.balance.gate_repair_rate)), int(order.inputs.materials)]
		if not str(order.blocked_reason).is_empty():
			row.label.text += "\n" + str(order.blocked_reason)
		row.cancel.text = "Cancel · +%d materials" % int(WorkOrders.refund(order).materials)
		if order.recipe == "road_remove":
			row.label.text = "%s · %d%% · return %d materials" % [title, int(100 * float(order.work_done) / float(order.work_required)), Roadworks.salvage(world, world.roadworks[order.target])]
			if not str(order.blocked_reason).is_empty():
				row.label.text += "\n" + str(order.blocked_reason)
			row.cancel.text = "Keep barricade"
	for socket: String in rows.keys():
		if socket not in active:
			remove_child(rows[socket].container)
			rows[socket].container.queue_free()
			rows.erase(socket)
	visible = not active.is_empty()


func _create(socket: String) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	add_child(container)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(label)
	var actions := HBoxContainer.new()
	container.add_child(actions)
	var show_site := Button.new()
	show_site.text = "Show"
	show_site.pressed.connect(func() -> void: located.emit(socket))
	actions.add_child(show_site)
	var picker := OptionButton.new()
	picker.custom_minimum_size.x = 150
	picker.item_selected.connect(func(index: int) -> void:
		assigned.emit(socket, str(picker.get_item_metadata(index)))
		picker.select(0))
	actions.add_child(picker)
	var priority := Button.new()
	priority.text = "Priority"
	priority.toggle_mode = true
	priority.toggled.connect(func(value: bool) -> void: prioritised.emit(socket, value))
	actions.add_child(priority)
	var cancel := Button.new()
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func() -> void: cancelled.emit(socket))
	actions.add_child(cancel)
	rows[socket] = {"container": container, "label": label, "cancel": cancel, "priority": priority, "picker": picker, "show": show_site}


func _workers(world: RefCounted, socket: String, picker: OptionButton) -> void:
	var signature: String = ""
	for a: Dictionary in world.survivors:
		signature += str(a.id) + ":" + Jobs.assignment_reason(world, socket, a) + ";"
	if picker.get_meta("workers", "") == signature:
		return
	picker.set_meta("workers", signature)
	picker.clear()
	picker.add_item("Assign…")
	picker.set_item_disabled(0, true)
	for a: Dictionary in world.survivors:
		var index: int = picker.item_count
		picker.add_item(a.name)
		picker.set_item_metadata(index, a.id)
		var reason: String = Jobs.assignment_reason(world, socket, a)
		picker.set_item_disabled(index, not reason.is_empty())
		picker.set_item_tooltip(index, reason)
	picker.select(0)
