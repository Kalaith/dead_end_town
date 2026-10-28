extends RefCounted
## Spatial events redirect existing actors; they never create or schedule enemies.


static func initial() -> Dictionary:
	return {"sequence": 0, "events": []}


static func emit(world: RefCounted, emitter: String, category: String, pos: Vector2) -> void:
	var config: Dictionary = world.catalog.attention.events[category]
	var key: String = category + ":" + emitter
	for event: Dictionary in world.noise.events:
		if event.key != key:
			continue
		if world.elapsed - float(event.updated) + 0.000001 < float(config.refresh):
			return
		event.x = pos.x
		event.y = pos.y
		event.updated = world.elapsed
		event.expires = world.elapsed + float(config.lifetime)
		return
	world.noise.sequence = int(world.noise.sequence) + 1
	world.noise.events.append({"id": int(world.noise.sequence), "emitter": emitter, "category": category, "key": key, "x": pos.x, "y": pos.y, "radius": float(config.radius), "updated": world.elapsed, "expires": world.elapsed + float(config.lifetime)})


static func age(world: RefCounted) -> void:
	var retained: Array = []
	for event: Dictionary in world.noise.events:
		if float(event.expires) > world.elapsed:
			retained.append(event)
	world.noise.events = retained
	var living: Dictionary = {}
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0:
			living[z.id] = true
	for id: String in world.memories.keys():
		if not living.has(id) or float(world.memories[id].expires) <= world.elapsed:
			world.memories.erase(id)


static func observe(world: RefCounted, z: Dictionary, target: Dictionary) -> void:
	if not target.is_empty():
		world.memories[z.id] = {"x": target.pos.x, "y": target.pos.y, "expires": world.elapsed + float(world.catalog.attention.memory_seconds)}


static func destination(world: RefCounted, z: Dictionary) -> Dictionary:
	if world.memories.has(z.id) and float(world.memories[z.id].expires) > world.elapsed:
		var memory: Dictionary = world.memories[z.id]
		return {"position": Vector2(float(memory.x), float(memory.y)), "source": "memory"}
	var event: Dictionary = strongest(world, z.pos)
	if event.is_empty():
		return {}
	return {"position": Vector2(float(event.x), float(event.y)), "source": str(event.id)}


static func strongest(world: RefCounted, listener: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var score: float = -1.0
	for event: Dictionary in world.noise.events:
		if float(event.expires) <= world.elapsed:
			continue
		var source := Vector2(float(event.x), float(event.y))
		var radius: float = float(event.radius)
		for property: Dictionary in world.catalog.properties:
			var building := Rect2(float(property.building[0]), float(property.building[1]), float(property.building[2]), float(property.building[3]))
			if _crosses(building, source, listener):
				radius *= 0.5
				break
		var strength: float = radius - source.distance_to(listener)
		if strength < 0:
			continue
		if strength > score or (strength == score and (best.is_empty() or float(event.updated) > float(best.updated) or (float(event.updated) == float(best.updated) and int(event.id) < int(best.id)))):
			best = event
			score = strength
	return best


static func _crosses(rect: Rect2, from: Vector2, to: Vector2) -> bool:
	if rect.has_point(from) or rect.has_point(to):
		return true
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i: int in range(4):
		if Geometry2D.segment_intersects_segment(from, to, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false
