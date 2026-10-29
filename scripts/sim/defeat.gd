extends RefCounted
const Pressure = preload("res://scripts/sim/pressure.gd")
const CompanionRescue = preload("res://scripts/sim/companion_rescue.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
const SliceObjective = preload("res://scripts/sim/slice_objective.gd")


static func begin(world: RefCounted) -> void:
	if world.defeat_pending:
		return
	world.defeat_pending = true
	world.downs += 1
	world.move_input = Vector2.ZERO
	world.working = false
	world.interacting = false
	SliceObjective.step(world, 0.0)


static func destination(world: RefCounted) -> Dictionary:
	var best: Dictionary = {}
	var distance: float = INF
	for p: Dictionary in world.catalog.properties:
		var point: Vector2 = Routes.point(p.site)
		if not world.properties[p.id].claimed or world.remaining(p.id) > 0 or not world.routes.walkable(point) or Combat.danger(world, point, 170):
			continue
		var next: float = world.player.pos.distance_squared_to(point)
		if next < distance:
			best = {"point": point, "name": p.name, "emergency": false}
			distance = next
	if best.is_empty():
		best = {"point": Routes.point(world.balance.emergency_shelter), "name": "West shelter", "emergency": true}
	return best


static func controlled(world: RefCounted, point: Vector2) -> bool:
	for d: Dictionary in world.catalog.crossings:
		if not Routes.rectangle(d.area).has_point(point):
			continue
		var held: bool = true
		for id: String in d.requires:
			held = held and world.properties[id].claimed
		for id: String in d.barriers:
			var s: Dictionary = world.roadworks[id]
			held = held and s.phase in ["ready", "dismantling"] and float(s.hp) > 0
		if held:
			return true
	return false


static func relocate(world: RefCounted, shelter: Vector2) -> void:
	for z: Dictionary in world.zombies:
		if float(z.hp) <= 0 or z.pos.distance_to(shelter) >= float(world.balance.recovery_clear_radius):
			continue
		var selected: Vector2 = Vector2.INF
		var distance: float = INF
		for x: int in range(30, int(world.catalog.bounds[0]) - 20, 20):
			for y: int in [550, 580, 610]:
				var point := Vector2(x, y)
				if point.distance_to(shelter) < float(world.balance.recovery_relocate_distance) or not world.routes.walkable(point) or controlled(world, point):
					continue
				var occupied: bool = false
				for other: Dictionary in world.zombies:
					if other.id != z.id and float(other.hp) > 0 and other.pos.distance_to(point) < 20:
						occupied = true
				if occupied:
					continue
				var next: float = z.pos.distance_squared_to(point)
				if next < distance:
					selected = point
					distance = next
		assert(selected.is_finite(), "Authored road must retain an uncontrolled recovery point")
		z.pos = selected


static func positions(world: RefCounted, point: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = [point]
	for ring: int in range(1, 5):
		var offsets: Array[Vector2] = [Vector2(ring, 0), Vector2(-ring, 0), Vector2(0, ring), Vector2(0, -ring)]
		for x: int in range(-ring, ring + 1):
			for y: int in range(-ring, ring + 1):
				if x != 0 and y != 0 and maxi(absi(x), absi(y)) == ring:
					offsets.append(Vector2(x, y))
		for offset: Vector2 in offsets:
			var candidate: Vector2 = point + offset * 24
			if world.routes.walkable(candidate) and not Combat.danger(world, candidate, 120):
				result.append(candidate)
	return result


static func recover(world: RefCounted) -> bool:
	if not world.defeat_pending:
		return false
	var d: Dictionary = destination(world)
	CompanionRescue.cancel_all(world)
	if d.emergency:
		relocate(world, d.point)
	var spots: Array[Vector2] = positions(world, d.point)
	world.player.pos = spots[0]
	world.player.hp = float(world.balance.defeat_player_health)
	var index: int = 1
	for a: Dictionary in world.survivors:
		if float(a.hp) <= 0:
			assert(index < spots.size(), "Recovery shelter needs one valid place per casualty")
			a.pos = spots[index]
			a.hp = float(world.balance.defeat_survivor_health)
			index += 1
	world.carry = Carrying.initial()
	Pressure.postpone(world, world.elapsed + float(world.balance.recovery_migration_seconds))
	world.defeat_pending = false
	world.move_input = Vector2.ZERO
	world.working = false
	world.interacting = false
	return true
