extends PanelContainer
const AreaTravel = preload("res://scripts/core/area_travel.gd")
## Closing screen when the community leaves the last area.
signal chosen(command: String)
var body: Label
var keep_button: Button
var shown: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(600, 320)
	# Centred on the screen at any layout size.
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	var heading := Label.new()
	heading.text = "Out of Dead End Town"
	heading.add_theme_font_size_override("font_size", 26)
	column.add_child(heading)
	body = Label.new()
	body.custom_minimum_size.x = 560
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	column.add_child(body)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	keep_button = Button.new()
	keep_button.text = "Keep exploring"
	keep_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keep_button.pressed.connect(func() -> void: chosen.emit("resume"))
	actions.add_child(keep_button)
	var again := Button.new()
	again.text = "New street"
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func() -> void: chosen.emit("new"))
	actions.add_child(again)


static func summary(world: RefCounted) -> String:
	var alive: int = 0
	for a: Dictionary in world.survivors:
		if float(a.hp) > 0:
			alive += 1
	var minutes: int = int(AreaTravel.played(world) / 60.0)
	return "%s\n\nYou and %d other survivor%s made it through, in %d minute%s, going down %d time%s on the way." % [str(world.catalog.exit.line), alive, "" if alive == 1 else "s", minutes, "" if minutes == 1 else "s", AreaTravel.downs(world), "" if AreaTravel.downs(world) == 1 else "s"]


func refresh(world: RefCounted) -> void:
	visible = world.campaign_ended
	if not visible:
		shown = false
		return
	body.text = summary(world)
	if not shown:
		shown = true
		keep_button.grab_focus()
