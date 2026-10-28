extends Control
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
var world: RefCounted
var selected: String = "home"
var work_point: Vector2 = Vector2.INF


func centre(id: String) -> Vector2:
	for column: int in range(world.catalog.town.columns.size()):
		var pair: Array = world.catalog.town.columns[column]
		if id in pair:
			return Vector2(38 + column * 64, 48 + pair.find(id) * 112)
	return Vector2.ZERO


func _draw() -> void:
	if world == null:
		return
	for link: Dictionary in world.catalog.passages + world.catalog.crossings:
		if link.requires[0] not in world.seen or link.requires[1] not in world.seen:
			continue
		var start: Vector2 = centre(link.requires[0])
		var finish: Vector2 = centre(link.requires[1])
		if Neighbourhood.link_reason(world, link).is_empty():
			draw_line(start, finish, Color("91c5a0"), 4.0)
		else:
			draw_dashed_line(start, finish, Color("d1a164"), 2.0, 6.0)
	for id: String in world.seen:
		var pos: Vector2 = centre(id)
		var held: bool = world.properties[id].claimed
		draw_rect(Rect2(pos - Vector2(26, 24), Vector2(52, 48)), Color("3d6955") if held else Color("53534a"))
		# The inset square marks held ground without relying on colour.
		if held:
			draw_rect(Rect2(pos - Vector2(7, 7), Vector2(14, 14)), Color("cbe0c3"), false, 2.0)
		if id == selected:
			draw_rect(Rect2(pos - Vector2(29, 27), Vector2(58, 54)), Color("dfb36e"), false, 3.0)
	var player_column: float = clampf((world.player.pos.x - 80.0) / 720.0, 0.0, 11.8)
	var player_y: float = clampf(world.player.pos.y / 1160.0, 0.0, 1.0)
	var player_pos := Vector2(12 + player_column * 64, 20 + player_y * 168)
	draw_circle(player_pos, 5.0, Color("f5e6c2"))
	draw_arc(player_pos, 8.0, 0.0, TAU, 20, Color("142426"), 2.0)
	if work_point.is_finite():
		var work_pos := Vector2(12 + (work_point.x - 80) / 720.0 * 64, 20 + work_point.y / 1160.0 * 168)
		draw_line(work_pos - Vector2(7, 7), work_pos + Vector2(7, 7), Color("dfb36e"), 3.0)
		draw_line(work_pos - Vector2(7, -7), work_pos + Vector2(7, -7), Color("dfb36e"), 3.0)
