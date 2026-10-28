extends PanelContainer
const Defeat = preload("res://scripts/sim/defeat.gd")
signal chosen(command: String)
var description: Label
var status: Label
var recover_button: Button
var load_button: Button
var shown: bool = false


func _ready() -> void:
	position = Vector2(340, 200)
	size = Vector2(600, 300)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	var heading := Label.new()
	heading.text = "Downed"
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)
	description = Label.new()
	description.custom_minimum_size.x = 560
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 18)
	column.add_child(description)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	recover_button = Button.new()
	recover_button.text = "Recover"
	recover_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recover_button.pressed.connect(func() -> void: chosen.emit("recover"))
	actions.add_child(recover_button)
	load_button = Button.new()
	load_button.text = "Load save"
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.pressed.connect(func() -> void: chosen.emit("load"))
	actions.add_child(load_button)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 18)
	column.add_child(status)


func refresh(world: RefCounted, message: String) -> void:
	visible = world.defeat_pending
	if not visible:
		shown = false
		return
	var d: Dictionary = Defeat.destination(world)
	var title: String = str(d.name).get_slice("/", 1).strip_edges().capitalize() if "/" in str(d.name) else str(d.name)
	description.text = "%s: you return at %d health; downed survivors at %d.\nSupplies and town damage stay. New raids wait %ds." % [title, int(world.balance.defeat_player_health), int(world.balance.defeat_survivor_health), int(world.balance.recovery_migration_seconds)]
	if d.emergency:
		description.text += "\nNearby zombies move to uncontrolled road."
	status.text = message
	status.visible = not message.is_empty()
	if not shown:
		shown = true
		recover_button.grab_focus()
