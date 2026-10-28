extends Control
## Local physical layout of discovered ground only; selection never moves the world.
const Routes = preload("res://scripts/sim/routes.gd")
var world: RefCounted
var selected: String = "home"
var focus: Vector2
var zoom: float = 0.3


func point(value: Vector2) -> Vector2:
	return (value - focus) * zoom + size * 0.5


func rectangle(value: Rect2) -> Rect2:
	return Rect2(point(value.position), value.size * zoom)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0e1b1c"))
	if world == null:
		return
	var p: Dictionary = world.definition(selected)
	focus = Routes.rectangle(p.rect).get_center().lerp(Routes.point(p.gate), 0.3)
	zoom = size.y / 580.0
	var known: Array[Rect2] = []
	for id: String in world.seen:
		var site: Dictionary = world.definition(id)
		var state: Dictionary = world.properties[id]
		var yard: Rect2 = rectangle(Routes.rectangle(site.rect))
		draw_rect(yard, Color("3d6955") if state.claimed else Color("45473d"))
		known.append(Routes.rectangle(site.rect).grow(8))
		draw_rect(rectangle(Routes.rectangle(site.building)), Color("5d6557"))
		var gate: Vector2 = point(Routes.point(site.gate))
		var broken: bool = float(state.gate_hp) <= 0
		# Erase the fence opening, then draw the actual open/closed gate leaf.
		draw_line(gate - Vector2(14, 0), gate + Vector2(14, 0), Color("45473d"), 4.0)
		if not broken:
			var finish: Vector2 = gate + (Vector2(-14, -17) if state.open else Vector2(14, 0))
			draw_line(gate - Vector2(14, 0), finish, Color("dfb36e"), 3.0)
		if id == selected:
			for corner: Vector2 in [yard.position, yard.end, Vector2(yard.end.x, yard.position.y), Vector2(yard.position.x, yard.end.y)]:
				draw_circle(corner, 3.0, Color("dfb36e"))
		if float(state.gate_hp) < float(world.balance.gate_health):
			draw_line(gate + Vector2(-14, 8), gate + Vector2(14, 8), Color("142426"), 3.0)
			draw_line(gate + Vector2(-14, 8), gate + Vector2(-14 + 28 * float(state.gate_hp) / float(world.balance.gate_health), 8), Color("d88c63"), 3.0)
	for d: Dictionary in world.catalog.passages:
		if d.requires[0] not in world.seen or d.requires[1] not in world.seen:
			continue
		if world.passages[d.id].done:
			known.append(Routes.rectangle(d.area).grow(8))
			draw_rect(rectangle(Routes.rectangle(d.area)), Color("45473d"))
	for wall: Rect2 in world.routes.walls:
		if minf(wall.size.x, wall.size.y) > 16:
			continue
		for area: Rect2 in known:
			if wall.intersects(area):
				draw_rect(rectangle(wall.intersection(area)), Color("968168"))
	for d: Dictionary in world.catalog.barricades:
		if d.requires[0] not in world.seen or d.requires[1] not in world.seen:
			continue
		var state: Dictionary = world.roadworks[d.id]
		if state.phase in ["ready", "dismantling"] and float(state.hp) > 0:
			draw_rect(rectangle(Routes.rectangle(d.rect)), Color("ab8860"))
	if Routes.rectangle(p.rect).has_point(world.player.pos):
		draw_circle(point(world.player.pos), 4.0, Color("f5e6c2"))
