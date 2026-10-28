extends VBoxContainer
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
signal cancelled(socket: String)
var rows: Dictionary = {}


static func available(world: RefCounted) -> bool:
	for order: Dictionary in world.orders.sites.values():
		if order.kind == "construction" and WorkOrders.pending(order):
			return true
	return false


func refresh(world: RefCounted) -> void:
	var active: Array[String] = []
	for socket: String in world.orders.sites:
		var order: Dictionary = world.orders.sites[socket]
		if order.kind != "construction" or not WorkOrders.pending(order):
			continue
		active.append(socket)
		if not rows.has(socket):
			_create(socket)
		var row: Dictionary = rows[socket]
		var title: String = "Passage"
		for d: Dictionary in world.catalog.passages:
			if d.id == order.target:
				title = d.name
		row.label.text = "%s · %d%% · %d materials committed" % [title, int(100 * float(order.work_done) / float(order.work_required)), int(order.inputs.materials)]
		if not str(order.blocked_reason).is_empty():
			row.label.text += "\n" + str(order.blocked_reason)
		row.cancel.text = "Cancel · +%d materials" % int(WorkOrders.refund(order).materials)
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
	var cancel := Button.new()
	cancel.pressed.connect(func() -> void: cancelled.emit(socket))
	container.add_child(cancel)
	rows[socket] = {"container": container, "label": label, "cancel": cancel}
