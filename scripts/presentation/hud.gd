extends Control
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const UiKit = preload("res://addons/hatchery/ui/ui_kit.gd")
const Palette = preload("res://addons/hatchery/ui/palette.gd")
const TeamOrders = preload("res://scripts/presentation/team_orders.gd")
signal requested(command: String)
signal assignment_requested(survivor_id: String, task: String)
var kit: RefCounted
var stats: Label
var objective: Label
var context_label: Label
var radio: Label
var team_orders: VBoxContainer
var supplies: Label
var menu: PanelContainer
var menu_status: Label
var pause_title: Label
var first_button: Button
var last_message: String = ""
var message_seconds: float = 0.0


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
	var header: PanelContainer = _panel(Vector2(16, 16), Vector2(440, 48))
	stats = kit.label("", 18)
	header.add_child(stats)
	var pause: Button = kit.button("Pause / Esc", func() -> void: requested.emit("menu"))
	pause.position = Vector2(1134, 16)
	pause.size = Vector2(130, 42)
	add_child(pause)
	context_label = kit.label("", 17, Color("dfb36e"))
	context_label.position = Vector2(20, 78)
	add_child(context_label)
	radio = kit.label("", 16, Color("c6e5cd"))
	radio.position = Vector2(20, 672)
	radio.size = Vector2(1240, 36)
	radio.add_theme_color_override("font_shadow_color", Color("142426"))
	radio.add_theme_constant_override("shadow_offset_x", 2)
	radio.add_theme_constant_override("shadow_offset_y", 2)
	add_child(radio)
	_build_menu()


func _panel(pos: Vector2, extent: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = extent
	add_child(panel)
	return panel


func _build_menu() -> void:
	menu = _panel(Vector2(200, 48), Vector2(880, 624))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	menu.add_child(column)
	pause_title = kit.heading("ONE STREET. A PLACE TO BEGIN.", 24)
	column.add_child(pause_title)
	column.add_child(kit.label("Search buildings and hold your ground.", 16))
	objective = kit.label("", 17, Color("dfb36e"))
	column.add_child(objective)
	supplies = kit.label("", 16)
	column.add_child(supplies)
	team_orders = TeamOrders.new()
	column.add_child(team_orders)
	team_orders.assigned.connect(func(id: String, task: String) -> void: assignment_requested.emit(id, task))
	column.add_child(kit.label("WASD / arrows  Move and face     Mouse  Aim\nClick  Swing at cursor     Space  Swing forward (hold to repeat)\nE  Interact     Hold R  Work     F  Team orders     G  Post road guard\n1-4  Entire team: Follow / Hold / Engage / Home     Esc / Tab  Pause", 15))
	first_button = kit.button("Begin", func() -> void: requested.emit("resume"), true)
	column.add_child(first_button)
	var row := HBoxContainer.new()
	column.add_child(row)
	for entry: Array in [["Save street", "save"], ["Load saved street", "load"], ["New street", "new"]]:
		var command: String = entry[1]
		var button: Button = kit.button(entry[0], func() -> void: requested.emit(command))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	menu_status = kit.label("Playable greybox / keyboard and mouse / no audio yet", 14)
	column.add_child(menu_status)


func refresh(world: RefCounted, paused: bool, dt: float = 0.0) -> void:
	stats.text = "HEALTH %d     HOME / %s" % [int(world.player.hp), world.alert]
	for p: Dictionary in world.catalog.properties:
		if world.alert == "SAFE" and world.properties[p.id].claimed and world.remaining(p.id) > 0:
			stats.text = "HEALTH %d     STREET / THREATENED" % int(world.player.hp)
	for d: Dictionary in world.catalog.barricades:
		if world.alert == "SAFE" and Roadworks.active(world.roadworks[d.id]) and Roadworks.danger(world, d):
			stats.text = "HEALTH %d     STREET / THREATENED" % int(world.player.hp)
	if not world.properties.home.claimed:
		stats.text = "HEALTH %d     HOME / LOST" % int(world.player.hp)
	if world.pressure.warned and stats.text.ends_with("SAFE"):
		stats.text = "HEALTH %d     RAID / IN %ds" % [int(world.player.hp), ceili(float(world.pressure.next) - world.elapsed)]
	stats.modulate = Color("e7dfc9") if world.alert == "SAFE" and not stats.text.contains("THREATENED") else Color("ffac82")
	objective.text = "NEXT / " + _goal(world)
	supplies.text = "STOCKPILE / %d materials     %d food" % [world.materials, world.food]
	context_label.text = world.context()
	context_label.visible = not paused and not context_label.text.is_empty()
	if paused:
		team_orders.refresh(world)
	var latest: String = world.messages.back() if not world.messages.is_empty() else ""
	if latest != last_message:
		last_message = latest
		message_seconds = 7.0
	if not paused:
		message_seconds = maxf(0.0, message_seconds - dt)
	radio.text = latest
	radio.visible = not paused and message_seconds > 0 and not latest.is_empty()
	menu.visible = paused


func _goal(world: RefCounted) -> String:
	for p: Dictionary in world.catalog.properties:
		if world.properties[p.id].looted and not world.properties[p.id].claimed:
			return "Clear and reclaim " + p.name + " at its porch with E."
	if world.workshop.equipped:
		return "Paige equipped. Use 4 to send the team home to guard."
	if world.workshop.armour_done:
		if not world.properties.library.claimed:
			return "The restored armour is stored at the workshop."
		return "Bring Paige to the workshop; E fits her armour and shield."
	if world.workshop.armour_started:
		return "Restore the armour with R or assign a survivor with F at the garage."
	if world.workshop.done:
		return "Start restoring the cached armour at the garage bench with E."
	if world.workshop.started:
		return "Restore the workshop with R or assign a survivor with F at the garage."
	if world.properties.garage.claimed:
		return "Restore the workshop at the garage porch with E."
	if world.garden_done:
		return "Explore the remaining properties."
	if world.properties.garden.claimed:
		if world.garden_started:
			return "Assign a gardener with F, or help build the beds with R."
		return "Start the garden with E, then hold R or assign a survivor with F."
	if float(world.properties.home.gate_hp) >= float(world.balance.gate_health) or world.properties.home.open:
		return "Explore east of home; search cleared buildings with E."
	return "Repair the home gate with R, then open it with E and head east."


func show_menu(intro: bool = false) -> void:
	menu.visible = true
	pause_title.text = "ONE STREET. A PLACE TO BEGIN." if intro else "THE STREET IS PAUSED"
	first_button.text = "Begin" if intro else "Return to the street"
	first_button.grab_focus()
