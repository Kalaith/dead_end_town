extends RefCounted
## One walkability model for player collision and AI routes. No scene nodes.
var walls: Array[Rect2] = []
var road_walls: Array[Rect2] = []
var grid := AStarGrid2D.new()
var bounds := Vector2(1440, 1160)
const CELL: float = 20.0
const RADIUS: float = 11.0


static func point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


static func rectangle(value: Array) -> Rect2:
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))


func rebuild(definitions: Array, properties: Dictionary, size: Vector2, defences: Array[Rect2] = []) -> void:
	road_walls = defences
	bounds = size
	walls.clear()
	for p: Dictionary in definitions:
		var rect: Rect2 = rectangle(p.rect)
		var gate: Vector2 = point(p.gate)
		walls.append(rectangle(p.building))
		walls.append(Rect2(rect.position, Vector2(8, rect.size.y)))
		walls.append(Rect2(Vector2(rect.end.x - 8, rect.position.y), Vector2(8, rect.size.y)))
		var gate_top: bool = gate.y == rect.position.y
		var fence_y: float = rect.position.y if gate_top else rect.end.y - 8
		var back_y: float = rect.end.y - 8 if gate_top else rect.position.y
		walls.append(Rect2(rect.position.x, back_y, rect.size.x, 8))
		walls.append(Rect2(rect.position.x, fence_y, gate.x - 44 - rect.position.x, 8))
		walls.append(Rect2(gate.x + 44, fence_y, rect.end.x - gate.x - 44, 8))
		if not properties[p.id].open and float(properties[p.id].gate_hp) > 0:
			walls.append(Rect2(gate.x - 44, fence_y, 88, 8))
	grid.region = Rect2i(0, 0, int(bounds.x / CELL), int(bounds.y / CELL))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL / 2, CELL / 2)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x: int in range(grid.region.size.x):
		for y: int in range(grid.region.size.y):
			grid.set_point_solid(Vector2i(x, y), not walkable(Vector2(x, y) * CELL + grid.offset))


func walkable(pos: Vector2) -> bool:
	if not Rect2(Vector2(RADIUS, RADIUS), bounds - Vector2.ONE * RADIUS * 2).has_point(pos):
		return false
	for wall: Rect2 in walls + road_walls:
		if wall.grow(RADIUS).has_point(pos):
			return false
	return true


func move(from: Vector2, to: Vector2, distance: float) -> Vector2:
	var change: Vector2 = from.direction_to(to) * minf(distance, from.distance_to(to))
	var next: Vector2 = from
	if walkable(next + Vector2(change.x, 0)):
		next.x += change.x
	if walkable(next + Vector2(0, change.y)):
		next.y += change.y
	return next


func waypoint(from: Vector2, to: Vector2) -> Vector2:
	var start := Vector2i(from / CELL)
	var end := Vector2i(to / CELL)
	if not grid.is_in_boundsv(start) or not grid.is_in_boundsv(end):
		return from
	if grid.is_point_solid(start) or grid.is_point_solid(end):
		return from
	var path: PackedVector2Array = grid.get_point_path(start, end)
	if path.is_empty():
		return from
	return path[1] if path.size() > 1 else to


func line_clear(from: Vector2, to: Vector2, over_low_barriers: bool = false) -> bool:
	var obstacles: Array[Rect2] = walls.duplicate()
	if not over_low_barriers:
		obstacles.append_array(road_walls)
	for wall: Rect2 in obstacles:
		if Geometry2D.segment_intersects_segment(from, to, wall.position, Vector2(wall.end.x, wall.position.y)) != null:
			return false
		if Geometry2D.segment_intersects_segment(from, to, Vector2(wall.end.x, wall.position.y), wall.end) != null:
			return false
		if Geometry2D.segment_intersects_segment(from, to, wall.end, Vector2(wall.position.x, wall.end.y)) != null:
			return false
		if Geometry2D.segment_intersects_segment(from, to, Vector2(wall.position.x, wall.end.y), wall.position) != null:
			return false
	return true
