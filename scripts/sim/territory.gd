extends RefCounted
## Occupation requires actual entry. Walls and road defences buy physical time.
const Routes = preload("res://scripts/sim/routes.gd")


static func step(world: RefCounted, dt: float) -> void:
	for p: Dictionary in world.catalog.properties:
		var state: Dictionary = world.properties[p.id]
		if not state.claimed:
			continue
		var rect: Rect2 = Routes.rectangle(p.rect)
		var defended: bool = false
		for a: Dictionary in [world.player] + world.survivors:
			if float(a.hp) > 0 and rect.has_point(a.pos):
				defended = true
		if defended or world.remaining(p.id) == 0:
			state.occupation = 0.0
			continue
		if float(state.occupation) == 0:
			world.note(p.name + " / Overrun! Return to defend the property.")
		state.occupation = minf(float(world.balance.territory_fall_seconds), float(state.occupation) + dt)
		if float(state.occupation) >= float(world.balance.territory_fall_seconds):
			state.claimed = false
			state.occupation = 0.0
			world.note(p.name + " / Lost to shamblers. Clear the yard and reclaim it.")
