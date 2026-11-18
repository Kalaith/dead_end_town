extends RefCounted
## One walkability model for player collision and AI routes. No scene nodes.
var walls: Array[Rect2] = []
var road_walls: Array[Rect2] = []
var grid := AStarGrid2D.new()
var safe_grid := AStarGrid2D.new()
var safe_signature: String = ""
var bounds := Vector2(1440, 1160)
const CELL: float = 20.0
const RADIUS: float = 11.0
const NO_CELL := Vector2i(-1, -1)


static func point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


static func rectangle(value: Array) -> Rect2:
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))


func rebuild(definitions: Array, properties: Dictionary, size: Vector2, defences: Array[Rect2] = [], openings: Array[Rect2] = [], passage_walls: Array[Rect2] = []) -> void:
	safe_signature = ""
	road_walls = defences
	bounds = size
	walls.clear()
	for p: Dictionary in definitions:
		var rect: Rect2 = rectangle(p.rect)
		var gate: Vector2 = point(p.gate)
		walls.append(rectangle(p.building))
		_side_wall(Rect2(rect.position, Vector2(8, rect.size.y)), openings)
		_side_wall(Rect2(Vector2(rect.end.x - 8, rect.position.y), Vector2(8, rect.size.y)), openings)
		var gate_top: bool = gate.y == rect.position.y
		var fence_y: float = rect.position.y if gate_top else rect.end.y - 8
		var back_y: float = rect.end.y - 8 if gate_top else rect.position.y
		_side_wall(Rect2(rect.position.x, back_y, rect.size.x, 8), openings)
		walls.append(Rect2(rect.position.x, fence_y, gate.x - 44 - rect.position.x, 8))
		walls.append(Rect2(gate.x + 44, fence_y, rect.end.x - gate.x - 44, 8))
		if not properties[p.id].open and float(properties[p.id].gate_hp) > 0:
			walls.append(Rect2(gate.x - 44, fence_y, 88, 8))
	walls.append_array(passage_walls)
	grid.clear()
	grid.region = Rect2i(0, 0, int(bounds.x / CELL), int(bounds.y / CELL))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL / 2, CELL / 2)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	# Rasterise obstacle footprints rather than testing every cell against every wall.
	# This keeps a full-town rebuild proportional to the occupied grid area.
	for x: int in range(grid.region.size.x):
		grid.set_point_solid(Vector2i(x, 0))
		grid.set_point_solid(Vector2i(x, grid.region.size.y - 1))
	for y: int in range(grid.region.size.y):
		grid.set_point_solid(Vector2i(0, y))
		grid.set_point_solid(Vector2i(grid.region.size.x - 1, y))
	for wall: Rect2 in walls + road_walls:
		var area: Rect2 = wall.grow(RADIUS)
		var first := Vector2i(ceili((area.position.x - grid.offset.x) / CELL), ceili((area.position.y - grid.offset.y) / CELL))
		var end := Vector2i(ceili((area.end.x - grid.offset.x) / CELL), ceili((area.end.y - grid.offset.y) / CELL))
		for x: int in range(maxi(0, first.x), mini(grid.region.size.x, end.x)):
			for y: int in range(maxi(0, first.y), mini(grid.region.size.y, end.y)):
				grid.set_point_solid(Vector2i(x, y))



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
	# Someone pressed against a fence, or a target on a fence line (a gate), sits in a cell the grid marks solid
	# although the spot itself is walkable. Path from and to the nearest open cell instead of giving up.
	start = _open_cell(start, from)
	end = _open_cell(end, to)
	if start == NO_CELL or end == NO_CELL:
		return from
	var path: PackedVector2Array = grid.get_point_path(start, end)
	if path.is_empty():
		return from
	return path[1] if path.size() > 1 else to


## `cell` when it is open, else the open cell within two cells nearest `pos`, else NO_CELL.
func _open_cell(cell: Vector2i, pos: Vector2) -> Vector2i:
	if not grid.is_point_solid(cell):
		return cell
	var best: Vector2i = NO_CELL
	var best_distance: float = INF
	for dx: int in range(-2, 3):
		for dy: int in range(-2, 3):
			var next: Vector2i = cell + Vector2i(dx, dy)
			if not grid.is_in_boundsv(next) or grid.is_point_solid(next):
				continue
			var distance: float = pos.distance_squared_to(grid.get_point_position(next))
			if distance < best_distance:
				best = next
				best_distance = distance
	return best


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


## Adds a fence run, cut along its length where a passage opening crosses it. Side fences run
## north-south and back fences east-west, so a passage can join lots either beside or behind each other.
func _side_wall(rect: Rect2, openings: Array[Rect2]) -> void:
	for opening: Rect2 in openings:
		if rect.intersects(opening):
			if rect.size.y >= rect.size.x:
				walls.append(Rect2(rect.position, Vector2(rect.size.x, opening.position.y - rect.position.y)))
				walls.append(Rect2(rect.position.x, opening.end.y, rect.size.x, rect.end.y - opening.end.y))
			else:
				walls.append(Rect2(rect.position, Vector2(opening.position.x - rect.position.x, rect.size.y)))
				walls.append(Rect2(opening.end.x, rect.position.y, rect.end.x - opening.end.x, rect.size.y))
			return
	walls.append(rect)


func travel_clear(from: Vector2, to: Vector2) -> bool:
	var steps: int = maxi(1, ceili(from.distance_to(to) / (RADIUS * 0.5)))
	for i: int in range(steps + 1):
		if not walkable(from.lerp(to, float(i) / float(steps))):
			return false
	return true


func safe_waypoint(from: Vector2, to: Vector2, areas: Array[Rect2]) -> Vector2:
	var signature: String = str(areas)
	if signature != safe_signature:
		safe_signature = signature
		safe_grid.region = grid.region
		safe_grid.cell_size = grid.cell_size
		safe_grid.offset = grid.offset
		safe_grid.diagonal_mode = grid.diagonal_mode
		safe_grid.update()
		for x: int in range(grid.region.size.x):
			for y: int in range(grid.region.size.y):
				var cell := Vector2i(x, y)
				var pos: Vector2 = Vector2(cell) * CELL + grid.offset
				safe_grid.set_point_solid(cell, grid.is_point_solid(cell) or not _inside(pos, areas))
	var start := Vector2i(from / CELL)
	var end := Vector2i(to / CELL)
	if not safe_grid.is_in_boundsv(start) or not safe_grid.is_in_boundsv(end) or safe_grid.is_point_solid(start) or safe_grid.is_point_solid(end):
		return from
	var path: PackedVector2Array = safe_grid.get_point_path(start, end)
	return path[1] if path.size() > 1 else (to if path.size() == 1 else from)


func safe_travel_clear(from: Vector2, to: Vector2, areas: Array[Rect2]) -> bool:
	var steps: int = maxi(1, ceili(from.distance_to(to) / (RADIUS * 0.5)))
	for i: int in range(steps + 1):
		var pos: Vector2 = from.lerp(to, float(i) / float(steps))
		if not walkable(pos) or not _inside(pos, areas):
			return false
	return true


func _inside(pos: Vector2, areas: Array[Rect2]) -> bool:
	for area: Rect2 in areas:
		if area.has_point(pos):
			return true
	return false
