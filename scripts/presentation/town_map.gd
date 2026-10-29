extends VBoxContainer
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Preview = preload("res://scripts/presentation/town_map_preview.gd")
const MapDrawing = preload("res://scripts/presentation/town_map_drawing.gd")
var selected: String = "home"
var sites: Dictionary = {}
var drawing: Control
var detail: Label
var preview: Control
var world: RefCounted


func _ready() -> void:
	drawing = MapDrawing.new()
	drawing.custom_minimum_size = Vector2(800, 208)
	add_child(drawing)
	var local := HBoxContainer.new()
	local.add_theme_constant_override("separation", 16)
	add_child(local)
	detail = Label.new()
	detail.custom_minimum_size.x = 380
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("font_size", 18)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	local.add_child(detail)
	preview = Preview.new()
	preview.custom_minimum_size = Vector2(400, 176)
	preview.clip_contents = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	local.add_child(preview)


func refresh(value: RefCounted) -> void:
	world = value
	if selected not in world.seen:
		selected = "home"
	drawing.world = world
	for p: Dictionary in world.catalog.properties:
		var id: String = p.id
		if not sites.has(id):
			var button := Button.new()
			button.flat = true
			button.pressed.connect(func() -> void: select_site(id))
			button.focus_entered.connect(func() -> void: select_site(id))
			drawing.add_child(button)
			sites[id] = button
		var box: Rect2 = drawing.lot(id)
		sites[id].position = box.position
		sites[id].size = box.size
		sites[id].visible = id in world.seen
		sites[id].tooltip_text = place_name(p) if id in world.seen else ""
	_update_detail()


func select_site(id: String) -> void:
	if world == null or id not in world.seen:
		return
	selected = id
	drawing.work_point = Vector2.INF
	_update_detail()


func _update_detail() -> void:
	var p: Dictionary = world.definition(selected)
	var state: Dictionary = world.properties[selected]
	var status: String = "Held" if state.claimed else "Unsecured"
	if not p.available:
		status = "Unfinished"
	elif state.claimed and not Neighbourhood.safe_connected(world, selected):
		status += " · no protected home route"
	detail.text = place_name(p) + " · " + status
	for link: Dictionary in world.catalog.passages + world.catalog.crossings:
		if selected not in link.requires or link.requires[0] not in world.seen or link.requires[1] not in world.seen:
			continue
		var other: String = link.requires[1] if link.requires[0] == selected else link.requires[0]
		var reason: String = Neighbourhood.link_reason(world, link)
		detail.text += "\n" + place_name(world.definition(other)) + " · " + ("usable" if reason.is_empty() else reason)
	drawing.world = world
	drawing.selected = selected
	drawing.queue_redraw()
	preview.world = world
	preview.selected = selected
	preview.queue_redraw()


func locate(value: RefCounted, point: Vector2) -> void:
	world = value
	var closest: float = INF
	for id: String in world.seen:
		var site: Array = world.definition(id).site
		var distance: float = point.distance_squared_to(Vector2(site[0], site[1]))
		if distance < closest:
			closest = distance
			selected = id
	drawing.work_point = point
	_update_detail()


static func place_name(p: Dictionary) -> String:
	return str(p.name).get_slice("/", 1).strip_edges().capitalize() if "/" in str(p.name) else str(p.name)
