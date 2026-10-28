extends PanelContainer
const Roster = preload("res://scripts/sim/roster.gd")
signal chosen(task: String)
var heading: Label
var dialogue: Label
var hold_button: Button
var home_button: Button
var current: String = ""


func _ready() -> void:
	position = Vector2(360, 220)
	size = Vector2(560, 230)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)
	dialogue = Label.new()
	dialogue.custom_minimum_size = Vector2(520, 72)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_theme_font_size_override("font_size", 18)
	column.add_child(dialogue)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	for entry: Array in [["Hold here", "hold"], ["Follow me", "follow"], ["Return home", "home"]]:
		var button := Button.new()
		button.text = entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: chosen.emit(entry[1]))
		actions.add_child(button)
		if entry[1] == "hold":
			hold_button = button
		if entry[1] == "home":
			home_button = button


func refresh(world: RefCounted) -> void:
	visible = not world.rescue_intro.is_empty()
	if not visible:
		current = ""
		return
	var d: Dictionary = Roster.definition(world.catalog, world.rescue_intro)
	heading.text = d.name
	dialogue.text = d.intro
	home_button.disabled = not world.safe_connected(d.site)
	home_button.tooltip_text = "Secure a protected home route first" if home_button.disabled else ""
	if current != world.rescue_intro:
		current = world.rescue_intro
		hold_button.grab_focus()
