extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")


static func paint(view: Node2D, world: RefCounted, font: Font) -> void:
	for d: Dictionary in world.catalog.barricades:
		var state: Dictionary = world.roadworks[d.id]
		var center: Vector2 = Routes.point(d.center)
		var near: bool = world.player.pos.distance_to(center) < 240
		if state.phase == "empty" and (not Roadworks.unlocked(world, d) or not near):
			continue
		var rect: Rect2 = Routes.rectangle(d.rect)
		var built: bool = Roadworks.active(state)
		var color := Color("c4a675") if built else Color("8bac9b")
		for y: int in range(int(rect.position.y), int(rect.end.y), 32):
			var origin := Vector2(rect.position.x - 4, y + 2)
			if built:
				view.draw_rect(Rect2(origin + Vector2(4, 4), Vector2(25, 28)), Color("182928"))
				view.draw_rect(Rect2(origin, Vector2(24, 26)), Color("7f684c"))
				view.draw_line(origin + Vector2(1, 3), origin + Vector2(22, 23), color, 4)
				view.draw_line(origin + Vector2(1, 23), origin + Vector2(22, 3), color, 3)
			else:
				view.draw_line(origin + Vector2(12, 0), origin + Vector2(12, 17), color, 3)
		for y: float in [rect.position.y, rect.end.y]:
			view.draw_rect(Rect2(center.x - 12, y - 8, 24, 16), color)
		if world.player.pos.distance_to(center) < float(world.balance.barricade_work_range):
			view.draw_circle(center, 17, Color("142426"))
			view.draw_string(font, center + Vector2(-5, 6), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, color)
		if state.phase in ["building", "dismantling"]:
			var duration: float = float(world.balance.barricade_seconds if state.phase == "building" else world.balance.barricade_remove_seconds)
			var pos: Vector2 = center + Vector2(-52, 35)
			_meter(view, pos, float(state.progress) / duration, color)
		elif built and (near or float(state.hp) < float(world.balance.barricade_health)):
			_meter(view, center + Vector2(-52, 35), float(state.hp) / float(world.balance.barricade_health), color)


static func _meter(view: Node2D, pos: Vector2, fraction: float, color: Color) -> void:
	view.draw_rect(Rect2(pos - Vector2.ONE, Vector2(106, 7)), Color("142426"))
	view.draw_rect(Rect2(pos, Vector2(104 * clampf(fraction, 0, 1), 5)), color)
