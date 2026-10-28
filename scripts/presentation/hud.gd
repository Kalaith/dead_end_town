extends Control
const LiveStatus = preload("res://scripts/presentation/live_status.gd")
const SliceObjective = preload("res://scripts/sim/slice_objective.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")
const EquipmentMenu = preload("res://scripts/presentation/equipment_menu.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const UiKit = preload("res://addons/hatchery/ui/ui_kit.gd")
const Palette = preload("res://addons/hatchery/ui/palette.gd")
const TeamOrders = preload("res://scripts/presentation/team_orders.gd")
signal requested(command: String)
signal equipment_requested(actor_id: String, slot: String, item_id: String)
signal assignment_requested(survivor_id: String, task: String)
var kit: RefCounted
var live_status: Control
var stats: Label
var objective: Label
var context_label: Label
var radio: Label
var team_orders: VBoxContainer
var supplies: Label
var menu: PanelContainer
var watch_button: Button
var equipment_menu: VBoxContainer
var routes_status: Label
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
	live_status = LiveStatus.new()
	live_status.position = Vector2(16, 16)
	live_status.size = Vector2(220, 36)
	add_child(live_status)
	stats = kit.label("", 18, Color("ffac82"))
	stats.position = Vector2(20, 60)
	add_child(stats)
	var pause: Button = kit.button("Ⅱ", func() -> void: requested.emit("menu"))
	pause.position = Vector2(1220, 16)
	pause.size = Vector2(44, 40)
	pause.tooltip_text = "Pause (Esc)"
	add_child(pause)
	context_label = kit.label("", 17, Color("dfb36e"))
	context_label.position = Vector2(20, 100)
	add_child(context_label)
	radio = kit.label("", 16, Color("c6e5cd"))
	radio.position = Vector2(20, 640)
	radio.size = Vector2(740, 64)
	radio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	pause_title = kit.heading("ONE STREET. A PLACE TO BEGIN.", 24)
	column.add_child(pause_title)
	column.add_child(kit.label("Search buildings and hold your ground.", 16))
	objective = kit.label("", 17, Color("dfb36e"))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(objective)
	first_button = kit.button("Begin", func() -> void: requested.emit("resume"), true)
	column.add_child(first_button)
	watch_button = kit.button("Begin neighbourhood watch", func() -> void: requested.emit("watch"))
	column.add_child(watch_button)
	supplies = kit.label("", 16)
	column.add_child(supplies)
	routes_status = kit.label("", 13)
	column.add_child(routes_status)
	team_orders = TeamOrders.new()
	column.add_child(team_orders)
	team_orders.assigned.connect(func(id: String, task: String) -> void: assignment_requested.emit(id, task))
	equipment_menu = EquipmentMenu.new()
	column.add_child(equipment_menu)
	equipment_menu.chosen.connect(func(id: String, slot: String, item: String) -> void: equipment_requested.emit(id, slot, item))
	column.add_child(kit.label("WASD / arrows  Move and face     Mouse  Aim\nRight click  Shoot pistol     Left click  Swing     Space  Swing forward (hold to repeat)\nE  Interact     R  Work     Q  Salvage     F  Orders/loadouts     G  Post guard\n1-4  Entire team: Follow / Hold / Engage / Home     Esc / Tab  Pause", 15))
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
	live_status.refresh(world)
	stats.text = ""
	if world.alert != "SAFE":
		stats.text = "Home breached" if world.alert == "BREACHED" else "Home threatened"
	for p: Dictionary in world.catalog.properties:
		if world.properties[p.id].claimed and world.remaining(p.id) > 0:
			stats.text = p.name + " threatened"
	for d: Dictionary in world.catalog.barricades:
		if Roadworks.active(world.roadworks[d.id]) and Roadworks.danger(world, d):
			stats.text = d.name + " under attack"
	if world.pressure.warned and stats.text.is_empty():
		stats.text = "Raid · %ds" % ceili(float(world.pressure.next) - world.elapsed)
	if not world.properties.home.claimed:
		stats.text = "Home lost"
	stats.visible = not paused and not stats.text.is_empty()
	live_status.visible = not paused
	objective.text = "NEXT / " + SliceObjective.next(world)
	watch_button.visible = world.slice_state.phase == "preparing" and world.properties.garden.looted and world.properties.library.looted and world.properties.garage.looted
	watch_button.disabled = not SliceObjective.readiness(world).is_empty()
	watch_button.tooltip_text = SliceObjective.readiness(world)
	supplies.text = "STOCKPILE / %d materials     %d food\n%s" % [world.materials, world.food, Provisions.summary(world)]
	context_label.text = world.context()
	context_label.visible = not paused and not context_label.text.is_empty()
	if paused:
		routes_status.text = Neighbourhood.summary(world)
		routes_status.visible = not routes_status.text.is_empty()
		team_orders.refresh(world)
		equipment_menu.refresh(world)
	var latest: String = world.messages.back() if not world.messages.is_empty() else ""
	if latest != last_message:
		last_message = latest
		message_seconds = 0.0 if paused else 5.0
	if not paused:
		message_seconds = maxf(0.0, message_seconds - dt)
	radio.text = latest
	radio.visible = not paused and message_seconds > 0 and not latest.is_empty()
	menu.visible = paused


func _goal(world: RefCounted) -> String:
	return SliceObjective.next(world)


func show_menu(intro: bool = false) -> void:
	menu.visible = true
	pause_title.text = "ONE STREET. A PLACE TO BEGIN." if intro else "THE STREET IS PAUSED"
	first_button.text = "Begin" if intro else "Return to the street"
	first_button.grab_focus()
