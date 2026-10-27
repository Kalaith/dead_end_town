extends Control
const UiKit = preload("res://addons/hatchery/ui/ui_kit.gd")
const Palette = preload("res://addons/hatchery/ui/palette.gd")
signal requested(command: String)
var kit: RefCounted
var stats: Label
var objective: Label
var context_label: Label
var radio: Label
var roster: Label
var menu: PanelContainer
var menu_status: Label
var pause_title: Label
var first_button: Button
var minimap: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var palette := Palette.new()
	palette.panel = Color("142426")
	palette.accent = Color("dfb36e")
	palette.text = Color("e7dfc9")
	palette.muted = Color("91a99e")
	palette.line = Color("3a534c")
	kit = UiKit.new(palette)
	theme = kit.theme()
	var header: PanelContainer = _panel(Vector2(16, 16), Vector2(1248, 96))
	var stack := VBoxContainer.new()
	header.add_child(stack)
	var row := HBoxContainer.new()
	stack.add_child(row)
	row.add_child(kit.heading("DEAD END TOWN", 26))
	row.add_spacer(false)
	stats = kit.label("", 17)
	row.add_child(stats)
	var pause: Button = kit.button("Pause / Esc", func() -> void: requested.emit("menu"))
	pause.custom_minimum_size = Vector2(130, 34)
	row.add_child(pause)
	objective = kit.label("", 16)
	stack.add_child(objective)
	var bottom: PanelContainer = _panel(Vector2(16, 566), Vector2(1248, 138))
	var lower := VBoxContainer.new()
	lower.add_theme_constant_override("separation", 5)
	bottom.add_child(lower)
	context_label = kit.label("", 18, Color("dfb36e"))
	lower.add_child(context_label)
	roster = kit.label("", 15)
	lower.add_child(roster)
	radio = kit.label("", 14, Color("a4c5b3"))
	lower.add_child(radio)
	lower.add_child(kit.label("WASD / arrows  Move     Mouse  Aim     Click / Space  Swing     E  Interact     Hold R  Work", 14))
	lower.add_child(kit.label("1  Follow     2  Hold     3  Engage     4  Return home     F  Mara: garden / guard     Tab  Planning pause", 14))
	_build_menu()


func _panel(pos: Vector2, extent: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = extent
	add_child(panel)
	return panel


func _build_menu() -> void:
	menu = _panel(Vector2(355, 155), Vector2(570, 365))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	menu.add_child(column)
	pause_title = kit.heading("ONE STREET. A PLACE TO BEGIN.", 24)
	column.add_child(pause_title)
	var explanation: Label = kit.label("Mara guards home while you reclaim the street.\nRepair the gate. Clear the garden yard. Secure its porch,\nthen plant food. The library holds Paige; the garage holds tools.\n\nThe whole street stays active while you are away.", 16)
	column.add_child(explanation)
	first_button = kit.button("Open the gate / Begin", func() -> void: requested.emit("resume"), true)
	column.add_child(first_button)
	var row := HBoxContainer.new()
	column.add_child(row)
	for entry: Array in [["Save street", "save"], ["Load saved street", "load"], ["New street", "new"]]:
		var command: String = entry[1]
		var button: Button = kit.button(entry[0], func() -> void: requested.emit(command))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	menu_status = kit.label("Early playable prototype / keyboard and mouse / no audio yet", 14)
	column.add_child(menu_status)


func refresh(world: RefCounted, paused: bool) -> void:
	stats.text = "HEALTH %d     MATERIALS %d     FOOD %d     HOME / %s" % [int(world.player.hp), world.materials, world.food, world.alert]
	var goal: String = "01 / Repair home gate with R, then open it with E and head east."
	if float(world.properties.home.gate_hp) >= float(world.balance.gate_health) or world.properties.home.open:
		goal = "02 / Clear the garden yard east of home, then secure its marked porch with E."
	if world.properties.garden.claimed:
		goal = "03 / Start the garden with E. Hold R to build, or assign Mara with F."
	if world.garden_done:
		goal = "04 / Cross the road: rescue Paige at the library or recover the garage tools."
	if world.garden_done and world.properties.library.claimed and world.properties.garage.claimed:
		goal = "STREET RECLAIMED / Garden growing. Paige rescued. Tools recovered. Keep your home defended."
	objective.text = ("PLANNING PAUSED / " if paused else "NEXT / ") + goal
	context_label.text = world.context()
	var people := PackedStringArray()
	for a: Dictionary in world.survivors:
		people.append("%s [%d] / %s" % [a.name, int(a.hp), a.activity])
	roster.text = "TEAM / " + "     |     ".join(people)
	radio.text = "RADIO / " + (world.messages.back() if not world.messages.is_empty() else "Quiet street.")
	menu.visible = paused


func show_menu(intro: bool = false) -> void:
	menu.visible = true
	pause_title.text = "ONE STREET. A PLACE TO BEGIN." if intro else "THE STREET IS PAUSED"
	first_button.text = "Open the gate / Begin" if intro else "Return to the street"
	first_button.grab_focus()
