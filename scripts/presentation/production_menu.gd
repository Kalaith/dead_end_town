extends VBoxContainer
## One known facility, one decision row. Authoritative changes go through commands.
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Production = preload("res://scripts/sim/production.gd")
signal configured(mode: String, target: int, reserve: int)
signal cancelled
var summary: Label
var mode: OptionButton
var target: SpinBox
var reserve: SpinBox
var cancel_button: Button
const MODES: Array[String] = ["stopped", "once", "repeat"]


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	mode = OptionButton.new()
	for label: String in ["Stop", "One batch", "Repeat to target"]:
		mode.add_item(label)
	mode.custom_minimum_size.x = 240
	row.add_child(mode)
	target = _amount(row, "Bullet target")
	reserve = _amount(row, "Keep materials")
	mode.item_selected.connect(func(_index: int) -> void: _submit())
	target.value_changed.connect(func(_value: float) -> void: _submit())
	reserve.value_changed.connect(func(_value: float) -> void: _submit())
	cancel_button = Button.new()
	cancel_button.pressed.connect(func() -> void: cancelled.emit())
	add_child(cancel_button)


func _amount(row: HBoxContainer, text: String) -> SpinBox:
	var column := VBoxContainer.new()
	row.add_child(column)
	var label := Label.new()
	label.text = text
	column.add_child(label)
	var value := SpinBox.new()
	value.min_value = 0
	value.max_value = 999
	value.step = 1
	value.custom_minimum_size.x = 160
	column.add_child(value)
	return value


func _submit() -> void:
	configured.emit(MODES[mode.selected], int(target.value), int(reserve.value))


func refresh(world: RefCounted) -> void:
	if not is_node_ready():
		return
	mode.select(MODES.find(world.production.mode))
	target.set_value_no_signal(float(world.production.target))
	reserve.set_value_no_signal(float(world.production.material_reserve))
	var order: Dictionary = WorkOrders.current(world, "munitions")
	var pending: bool = WorkOrders.pending(order)
	var rules: Dictionary = world.catalog.firearm
	summary.text = "Bullets · %d materials → %d bullets · %ds\nAvailable: %d materials · %d bullets" % [int(rules.material_cost), int(rules.batch_bullets), int(rules.craft_seconds), world.materials, int(world.firearms.bullets)]
	if pending:
		summary.text += "\nCommitted: %d materials · %d bullets pending · %d%%" % [int(order.inputs.materials), Production.pending_output(world), int(100 * float(order.work_done) / float(order.work_required))]
	var reason: String = str(world.production.reason)
	if not reason.is_empty():
		summary.text += "\n" + reason
	cancel_button.visible = pending
	if pending:
		cancel_button.text = "Cancel batch · return %d materials" % int(WorkOrders.refund(order).materials)
