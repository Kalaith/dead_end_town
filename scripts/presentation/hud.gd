extends Control
const SettingsStore = preload("res://addons/hatchery/settings/settings_store.gd")
const DefeatMenu = preload("res://scripts/presentation/defeat_menu.gd")
const EndingMenu = preload("res://scripts/presentation/ending_menu.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
const Tips = preload("res://scripts/sim/tips.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const RescueMenu = preload("res://scripts/presentation/rescue_menu.gd")
const ConstructionMenu = preload("res://scripts/presentation/construction_menu.gd")
const ProductionMenu = preload("res://scripts/presentation/production_menu.gd")
const LiveStatus = preload("res://scripts/presentation/live_status.gd")
const SliceObjective = preload("res://scripts/sim/slice_objective.gd")
const FoodGrowing = preload("res://scripts/sim/food_growing.gd")
const Provisions = preload("res://scripts/sim/provisions.gd")
const Readiness = preload("res://scripts/sim/readiness.gd")
const EquipmentMenu = preload("res://scripts/presentation/equipment_menu.gd")
const TownMap = preload("res://scripts/presentation/town_map.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const UiKit = preload("res://addons/hatchery/ui/ui_kit.gd")
const Palette = preload("res://addons/hatchery/ui/palette.gd")
const TeamOrders = preload("res://scripts/presentation/team_orders.gd")
const SaveSlots = preload("res://scripts/core/save_slots.gd")
const SlotControls = preload("res://scripts/presentation/slot_controls.gd")
const CreditsPage = preload("res://addons/hatchery/ui/credits_page.gd")
signal rescue_requested(task: String)
signal medicine_requested(mode: String, target: int, reserve: int)
signal medicine_cancelled
signal production_requested(mode: String, target: int, reserve: int)
signal work_prioritised(socket: String, value: bool)
signal work_cancelled(socket: String)
signal work_located(socket: String)
signal work_assigned(socket: String, id: String)
signal production_cancelled
signal requested(command: String)
signal slot_named(text: String)
signal equipment_requested(actor_id: String, slot: String, item_id: String)
signal assignment_requested(survivor_id: String, task: String)
var sections: Dictionary = {}
var section_buttons: Dictionary = {}
var section: String = "Street"
var construction_menu: VBoxContainer
var work_menu: VBoxContainer
var medicine_menu: VBoxContainer
var kit: RefCounted
var live_status: Control
var stats: Label
var objective: Label
var context_label: Label
var casualty_label: Label
var tip_panel: PanelContainer
var tip_label: Label
var tip_log: Label
var tips_on: bool = true
var tip_switch: Button
## Preferences live apart from the saved street, so starting a new street keeps them.
var settings := SettingsStore.new({"tips": true, "slot": 1, "slot_name_1": "", "slot_name_2": "", "slot_name_3": ""})
var radio: Label
var team_orders: VBoxContainer
var supplies: Label
var menu: PanelContainer
var rescue_menu: PanelContainer
var defeat_menu: PanelContainer
var ending_menu: PanelContainer
var equipment_menu: VBoxContainer
var town_map: VBoxContainer
var menu_status: Label
var slot_button: Button
var slot_controls: HBoxContainer
var pause_title: Label
var readiness: Label
var first_button: Button
var last_message: String = ""
var message_seconds: float = 0.0


func _init() -> void:
	# The chosen save slot is 1 to 3, not the store's default 0..1 range.
	settings.ranges["slot"] = Vector2(1, SaveSlots.COUNT)


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
	_pin(pause, Vector2(1, 0), Rect2(-60, 16, 44, 40))
	pause.tooltip_text = "Pause (Esc)"
	add_child(pause)
	context_label = kit.label("", 17, Color("dfb36e"))
	context_label.position = Vector2(20, 100)
	add_child(context_label)
	casualty_label = kit.label("", 15, Color("ffac82"))
	casualty_label.position = Vector2(20, 130)
	add_child(casualty_label)
	tip_panel = _panel(Vector2.ZERO, Vector2(400, 64))
	_pin(tip_panel, Vector2(1, 0), Rect2(-420, 76, 400, 64))
	tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_label = kit.label("", 16, Color("c6e5cd"))
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_panel.add_child(tip_label)
	radio = kit.label("", 16, Color("c6e5cd"))
	_pin(radio, Vector2(0, 1), Rect2(20, -80, 740, 64))
	radio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio.add_theme_color_override("font_shadow_color", Color("142426"))
	radio.add_theme_constant_override("shadow_offset_x", 2)
	radio.add_theme_constant_override("shadow_offset_y", 2)
	add_child(radio)
	_build_menu()
	resized.connect(_layout)
	_layout()
	rescue_menu = RescueMenu.new()
	add_child(rescue_menu)
	rescue_menu.chosen.connect(func(task: String) -> void: rescue_requested.emit(task))
	defeat_menu = DefeatMenu.new()
	add_child(defeat_menu)
	defeat_menu.chosen.connect(func(command: String) -> void: requested.emit(command))
	ending_menu = EndingMenu.new()
	add_child(ending_menu)
	ending_menu.chosen.connect(func(command: String) -> void: requested.emit(command))


## Pins `control` to the `corner` of the screen (0 or 1 on each axis), `rect` offset from it.
func _pin(control: Control, corner: Vector2, rect: Rect2) -> void:
	control.anchor_left = corner.x
	control.anchor_right = corner.x
	control.anchor_top = corner.y
	control.anchor_bottom = corner.y
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


## The pause menu grows with the screen (880 wide at 1280, up to 1240) and stays centred.
func _layout() -> void:
	if menu == null:
		return
	var extent := Vector2(clampf(size.x - 400.0, 880.0, 1240.0), maxf(size.y - 96.0, 480.0))
	menu.position = ((size - extent) / 2.0).floor()
	menu.size = extent


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
	pause_title = kit.heading("DEAD END TOWN", 24)
	column.add_child(pause_title)
	first_button = kit.button("Begin", func() -> void: requested.emit("resume"), true)
	column.add_child(first_button)
	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	for label: String in ["Street", "Team", "Work", "Loadouts", "Town", "Help"]:
		var button: Button = kit.button(label, func() -> void: show_section(label))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
		section_buttons[label] = button
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 12)
		column.add_child(page)
		sections[label] = page
	objective = kit.label("", 18, Color("dfb36e"))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sections.Street.add_child(objective)
	supplies = kit.label("", 18)
	sections.Street.add_child(supplies)
	readiness = kit.label("", 18)
	sections.Street.add_child(readiness)
	town_map = TownMap.new()
	sections.Town.add_child(town_map)
	team_orders = TeamOrders.new()
	sections.Team.add_child(team_orders)
	team_orders.assigned.connect(func(id: String, task: String) -> void: assignment_requested.emit(id, task))
	equipment_menu = EquipmentMenu.new()
	sections.Loadouts.add_child(equipment_menu)
	equipment_menu.chosen.connect(func(id: String, slot: String, item: String) -> void: equipment_requested.emit(id, slot, item))
	construction_menu = ConstructionMenu.new()
	construction_menu.located.connect(func(socket: String) -> void: work_located.emit(socket))
	construction_menu.assigned.connect(func(socket: String, id: String) -> void: work_assigned.emit(socket, id))
	sections.Work.add_child(construction_menu)
	construction_menu.prioritised.connect(func(socket: String, value: bool) -> void: work_prioritised.emit(socket, value))
	construction_menu.cancelled.connect(func(socket: String) -> void: work_cancelled.emit(socket))
	work_menu = ProductionMenu.new()
	sections.Work.add_child(work_menu)
	work_menu.configured.connect(func(mode: String, target: int, reserve: int) -> void: production_requested.emit(mode, target, reserve))
	work_menu.cancelled.connect(func() -> void: production_cancelled.emit())
	medicine_menu = ProductionMenu.new()
	medicine_menu.medicine_mode = true
	sections.Work.add_child(medicine_menu)
	medicine_menu.configured.connect(func(mode: String, target: int, reserve: int) -> void: medicine_requested.emit(mode, target, reserve))
	medicine_menu.cancelled.connect(func() -> void: medicine_cancelled.emit())
	sections.Help.add_child(kit.label("WASD / arrows  Move     Mouse  Aim\nRight click  Shoot     Left click / Space  Swing (hold to repeat)\nE  Interact / drop     Hold E  Carry casualty\nHold R  Work     Q  Timber\nF  Team     J  Work     M  Town     G  Post guard\n1–4  Follow / Hold / Engage / Home     Esc / Tab  Pause", 18))
	tip_switch = kit.button("Tips: on")
	tip_switch.pressed.connect(_toggle_tips)
	sections.Help.add_child(tip_switch)
	sections.Help.add_child(kit.button("Credits", func() -> void: CreditsPage.open(self, kit)))
	tip_log = kit.label("", 17)
	tip_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sections.Help.add_child(tip_log)
	var row := HBoxContainer.new()
	sections.Street.add_child(row)
	slot_button = kit.button("Slot 1", func() -> void: requested.emit("slot"))
	slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slot_button)
	for entry: Array in [["Save", "save"], ["Load", "load"], ["New street", "new"]]:
		var command: String = entry[1]
		var button: Button = kit.button(entry[0], func() -> void: requested.emit(command))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	slot_controls = SlotControls.new()
	slot_controls.build(kit)
	sections.Street.add_child(slot_controls)
	slot_controls.named.connect(func(text: String) -> void: slot_named.emit(text))
	slot_controls.delete_confirmed.connect(func() -> void: requested.emit("delete"))
	menu_status = kit.label("", 18)
	menu_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(menu_status)
	show_section("Street")


func show_section(value: String) -> void:
	section = value
	for label: String in sections:
		sections[label].visible = label == value
		section_buttons[label].disabled = label == value
	menu.get_child(0).scroll_vertical = 0


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
		stats.text = "Arrivals · %s" % ("entering" if world.pressure.phase == "entering" else "%ds" % maxi(0, ceili(float(world.pressure.next) - world.elapsed)))
	if not world.properties.home.claimed:
		stats.text = "Home lost"
	stats.visible = not paused and not stats.text.is_empty()
	live_status.visible = not paused
	objective.text = "NEXT / " + SliceObjective.next(world)
	supplies.text = "STOCKPILE / %d materials     %d food\n%s" % [world.materials, world.food, Provisions.summary(world)]
	if Facility.state(world, "clinic").looted:
		supplies.text += "\n%d medicine" % world.medicine
	supplies.text += "\n" + FoodGrowing.summary(world)
	readiness.text = "READINESS / advisory\n" + Readiness.summary(world)
	context_label.text = world.context()
	context_label.visible = not paused and not context_label.text.is_empty()
	var tip: String = Tips.text(world, Tips.current(world))
	tip_label.text = "TIP / " + tip
	tip_panel.visible = tips_on and not paused and not tip.is_empty() and world.rescue_intro.is_empty() and not world.campaign_ended
	tip_log.text = "Tips follow what is happening, one at a time.\n\n" + ("Now: " + tip if not tip.is_empty() else "Nothing to teach right now.")
	casualty_label.text = Carrying.roll(world)
	casualty_label.visible = not paused and not casualty_label.text.is_empty()
	if paused:
		if section == "Town":
			town_map.refresh(world)
		section_buttons.Work.visible = world.clinic.done or Facility.state(world, "munitions").looted or ConstructionMenu.available(world)
		construction_menu.refresh(world)
		work_menu.visible = Facility.state(world, "munitions").looted
		if section == "Work" and not section_buttons.Work.visible:
			show_section("Street")
		work_menu.refresh(world)
		medicine_menu.visible = world.clinic.done
		if medicine_menu.visible:
			medicine_menu.refresh(world)
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
	rescue_menu.refresh(world)
	rescue_menu.visible = rescue_menu.visible and not world.defeat_pending and not world.campaign_ended
	defeat_menu.refresh(world, menu_status.text)
	ending_menu.refresh(world)
	menu.visible = paused and world.rescue_intro.is_empty() and not world.defeat_pending and not world.campaign_ended


func _toggle_tips() -> void:
	_set_tips(not tips_on)
	settings.set_value("tips", tips_on)
	settings.save_settings()


func _set_tips(on: bool) -> void:
	tips_on = on
	tip_switch.text = "Tips: on" if tips_on else "Tips: off"


## Reads the saved preferences; `enabled` is false for runs that must not touch disk.
func load_preferences(enabled: bool) -> void:
	settings.save_enabled = enabled
	if enabled:
		settings.load_settings()
	_set_tips(bool(settings.values.tips))


func _goal(world: RefCounted) -> String:
	return SliceObjective.next(world)


func show_menu(intro: bool = false) -> void:
	menu.visible = true
	pause_title.text = "DEAD END TOWN" if intro else "PAUSED"
	first_button.text = "Begin" if intro else "Resume"
	first_button.grab_focus()
