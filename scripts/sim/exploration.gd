extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")


static func update(world: RefCounted) -> void:
	for p: Dictionary in world.catalog.properties:
		if not world.seen.has(p.id) and Routes.rectangle(p.rect).grow(float(world.balance.scout_range)).has_point(world.player.pos):
			world.seen.append(p.id)
