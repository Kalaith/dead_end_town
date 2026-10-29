extends Control
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var world: RefCounted
var selected: String = "home"
var work_point: Vector2 = Vector2.INF


## The whole area is fitted into this control, so any layout draws at a readable size.
func fit() -> float:
	return minf((size.x - 24.0) / float(world.catalog.bounds[0]), (size.y - 24.0) / float(world.catalog.bounds[1]))


func to_map(pos: Vector2) -> Vector2:
	var ratio: float = fit()
	var used := Vector2(float(world.catalog.bounds[0]), float(world.catalog.bounds[1])) * ratio
	return (size - used) / 2.0 + pos * ratio


func lot(id: String) -> Rect2:
	var rect: Rect2 = Routes.rectangle(world.definition(id).rect)
	return Rect2(to_map(rect.position), rect.size * fit())


func centre(id: String) -> Vector2:
	return lot(id).get_center()


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
		var box: Rect2 = lot(id)
		var held: bool = world.properties[id].claimed
		draw_rect(box, Color("3d6955") if held else Color("53534a"))
		# The inset square marks held ground without relying on colour.
		if held:
			draw_rect(Rect2(pos - Vector2(7, 7), Vector2(14, 14)), Color("cbe0c3"), false, 2.0)
		if id == selected:
			draw_rect(box.grow(3), Color("dfb36e"), false, 3.0)
	var player_pos: Vector2 = to_map(world.player.pos)
	draw_circle(player_pos, 5.0, Color("f5e6c2"))
	draw_arc(player_pos, 8.0, 0.0, TAU, 20, Color("142426"), 2.0)
	if work_point.is_finite():
		var work_pos: Vector2 = to_map(work_point)
		draw_line(work_pos - Vector2(7, 7), work_pos + Vector2(7, 7), Color("dfb36e"), 3.0)
		draw_line(work_pos - Vector2(7, -7), work_pos + Vector2(7, -7), Color("dfb36e"), 3.0)
