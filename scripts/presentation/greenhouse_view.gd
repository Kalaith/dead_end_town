extends RefCounted
## Glass matches the solid building footprint; outdoor soil rows stay walkable.


static func building(view: Node2D, area: Rect2) -> void:
	view.draw_rect(Rect2(area.position + Vector2(8, 12), area.size), Color(0, 0, 0, 0.25))
	view.draw_rect(area, Color("52746c"))
	for x: int in range(int(area.position.x) + 8, int(area.end.x) - 8, 42):
		for y: int in range(int(area.position.y) + 8, int(area.end.y) - 36, 46):
			var pane := Rect2(x, y, 34, 37)
			view.draw_rect(pane, Color("81a59c"))
			view.draw_line(pane.position + Vector2(5, 27), pane.position + Vector2(24, 8), Color("a8c4b2"), 2)
	view.draw_rect(area, Color("c3c7ab"), false, 5)
	view.draw_line(Vector2(area.position.x, area.get_center().y), Vector2(area.end.x, area.get_center().y), Color("c3c7ab"), 4)
	# The facade is closed; the work point is outside, beside the tool shed.
	view.draw_rect(Rect2(area.get_center().x - 18, area.end.y - 48, 36, 48), Color("394b4b"))
	view.draw_line(Vector2(area.get_center().x - 18, area.end.y - 48), Vector2(area.get_center().x + 18, area.end.y), Color("ab8860"), 6)


static func beds(view: Node2D, world: RefCounted, site: Vector2) -> void:
	for side: int in [-1, 1]:
		for row: int in range(3):
			var origin: Vector2 = site + Vector2(-218 if side < 0 else 82, -18 + row * 36)
			view.draw_rect(Rect2(origin, Vector2(136, 26)), Color("594937"))
			view.draw_rect(Rect2(origin, Vector2(136, 26)), Color("ab8860"), false, 2)
			for col: int in range(6):
				var plant: Vector2 = origin + Vector2(12 + col * 22, 13)
				var leaves: Color = Color("9dceb3") if world.greenhouse.done else Color("698e50")
				view.draw_line(plant - Vector2(5, 4), plant + Vector2(5, 4), leaves, 3)
				view.draw_line(plant + Vector2(-5, 4), plant + Vector2(5, -4), leaves, 3)
	if world.greenhouse.started:
		var fraction: float = float(world.greenhouse.harvest) / float(world.balance.greenhouse_food_seconds) if world.greenhouse.done else float(world.greenhouse.progress) / float(world.balance.greenhouse_seconds)
		view._meter(site + Vector2(-60, 84), 120, fraction, Color("9dceb3"))
	if world.greenhouse.done:
		view.draw_rect(Rect2(site + Vector2(-65, 38), Vector2(28, 25)), Color("ab8860"))
		for i: int in range(3):
			view.draw_circle(site + Vector2(-59 + i * 8, 43 + (i % 2) * 8), 4, Color("dfad62"))
