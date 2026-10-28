extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")


static func paint(view: Node2D, world: RefCounted) -> void:
	for d: Dictionary in world.catalog.passages:
		var s: Dictionary = world.passages[d.id]
		if not s.done:
			if Neighbourhood.owned(world, d):
				for site: Array in d.sites:
					var pos: Vector2 = Routes.point(site)
					if world.player.pos.distance_to(pos) < float(world.balance.passage_range):
						view.draw_arc(pos, 20, 0, TAU, 24, Color("9dceb3"), 2)
						if s.started:
							view._meter(pos + Vector2(-25, 26), 50, float(s.progress) / float(world.balance.passage_seconds), Color("9dceb3"))
			continue
		var area: Rect2 = Routes.rectangle(d.area)
		view.draw_rect(area.grow(-8), Color("686855"))
		for x: int in range(int(area.position.x) + 12, int(area.end.x), 20):
			view.draw_line(Vector2(x, area.position.y + 10), Vector2(x, area.end.y - 10), Color("79745d"), 2)
		for raw: Array in d.rails:
			view.draw_rect(Routes.rectangle(raw), Color("968168"))
		if float(s.hp) > 0:
			var gate: Rect2 = Routes.rectangle(d.gate)
			if s.open:
				view.draw_line(gate.position, gate.position + Vector2(65, 0), Color("9dceb3"), 7)
			else:
				view.draw_rect(gate, Color("9dceb3"))
		if not Neighbourhood.nearby(world).is_empty() and Neighbourhood.nearby(world).id == d.id:
			view._meter(area.get_center() + Vector2(-30, 25), 60, float(s.hp) / float(world.balance.gate_health), Color("9dceb3"))
