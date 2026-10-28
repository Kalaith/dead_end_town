extends VBoxContainer
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const MapDrawing = preload("res://scripts/presentation/town_map_drawing.gd")
var selected: String = "home"
var sites: Dictionary = {}
var drawing: Control
var detail: Label
var world: RefCounted


func _ready() -> void:
	drawing = MapDrawing.new()
	drawing.custom_minimum_size = Vector2(800, 208)
	add_child(drawing)
	detail = Label.new()
	detail.add_theme_font_size_override("font_size", 18)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(detail)


func refresh(value: RefCounted) -> void:
	world = value
	if selected not in world.seen:
		selected = "home"
	for column: int in range(world.catalog.town.columns.size()):
		for side: int in range(2):
			var id: String = world.catalog.town.columns[column][side]
			if not sites.has(id):
				var button := Button.new()
				button.position = Vector2(12 + column * 64, 24 + side * 112)
				button.size = Vector2(52, 48)
				button.flat = true
				button.pressed.connect(func() -> void: select_site(id))
				button.focus_entered.connect(func() -> void: select_site(id))
				drawing.add_child(button)
				sites[id] = button
			sites[id].visible = id in world.seen
			sites[id].tooltip_text = world.definition(id).name if id in world.seen else ""
	_update_detail()


func select_site(id: String) -> void:
	if world == null or id not in world.seen:
		return
	selected = id
	_update_detail()


func _update_detail() -> void:
	var p: Dictionary = world.definition(selected)
	var state: Dictionary = world.properties[selected]
	var status: String = "Held" if state.claimed else "Unsecured"
	if not p.available:
		status = "Unfinished"
	elif state.claimed and not Neighbourhood.safe_connected(world, selected):
		status += " · no protected home route"
	detail.text = str(p.name) + " · " + status
	for link: Dictionary in world.catalog.passages + world.catalog.crossings:
		if selected not in link.requires or link.requires[0] not in world.seen or link.requires[1] not in world.seen:
			continue
		var other: String = link.requires[1] if link.requires[0] == selected else link.requires[0]
		var reason: String = Neighbourhood.link_reason(world, link)
		detail.text += "\n" + str(world.definition(other).name) + " · " + ("usable" if reason.is_empty() else reason)
	drawing.world = world
	drawing.selected = selected
	drawing.queue_redraw()
