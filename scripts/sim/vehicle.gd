extends RefCounted
## The single utility van: driven by the protagonist only, blocked by anything solid, noisy while moving.
## State is plain numbers (x, y, heading in radians, speed, hull) so it saves as JSON.
const Acoustics = preload("res://scripts/sim/noise.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const VanRepair = preload("res://scripts/sim/van_repair.gd")


static func initial(catalog: Dictionary) -> Dictionary:
	var state: Dictionary = {"present": catalog.has("vehicle_bay"), "x": 0.0, "y": 0.0, "heading": 0.0, "speed": 0.0, "hull": 0.0, "driving": false, "riders": [], "repair_paid": false, "repair_progress": 0.0}
	if state.present:
		state.x = float(catalog.vehicle_bay.position[0])
		state.y = float(catalog.vehicle_bay.position[1])
		state.heading = deg_to_rad(float(catalog.vehicle_bay.heading_degrees))
		state.hull = float(catalog.vehicle.hull)
	return state


static func driving(world: RefCounted) -> bool:
	return bool(world.vehicle.driving)


## True for the driver and for anyone seated in the van: they take no direct hits and do not block it.
static func occupant(world: RefCounted, person: Dictionary) -> bool:
	return driving(world) and (person.id == "you" or world.vehicle.riders.has(person.id))


static func pos(world: RefCounted) -> Vector2:
	return Vector2(float(world.vehicle.x), float(world.vehicle.y))


static func forward(heading: float) -> Vector2:
	return Vector2.from_angle(heading)


## True when the footprint at this pose touches no wall, gate, barricade, map edge, zombie or survivor.
static func fits(world: RefCounted, at: Vector2, heading: float) -> bool:
	var config: Dictionary = world.catalog.vehicle
	var length: float = float(config.half_length)
	var width: float = float(config.half_width)
	var ahead: Vector2 = forward(heading)
	var side: Vector2 = ahead.orthogonal()
	var bounds := Rect2(Vector2.ZERO, world.routes.bounds)
	var solids: Array[Rect2] = world.routes.walls + world.routes.road_walls
	for u: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var p: Vector2 = at + ahead * u * length + side * v * width
			if not bounds.has_point(p):
				return false
			for wall: Rect2 in solids:
				if wall.has_point(p):
					return false
	# Living and downed people, and living zombies, block the swept footprint.
	for other: Dictionary in world.zombies:
		if float(other.hp) > 0 and _overlaps(other.pos - at, ahead, side, length, width):
			return false
	for other: Dictionary in world.survivors:
		if not occupant(world, other) and _overlaps(other.pos - at, ahead, side, length, width):
			return false
	return true


static func _overlaps(local: Vector2, ahead: Vector2, side: Vector2, length: float, width: float) -> bool:
	return absf(local.dot(ahead)) < length + 9.0 and absf(local.dot(side)) < width + 9.0


static func near(world: RefCounted) -> bool:
	if not bool(world.vehicle.present) or float(world.vehicle.hull) <= 0 or driving(world):
		return false
	return world.player.pos.distance_to(pos(world)) <= float(world.catalog.vehicle.enter_range)


## E: board when beside a stopped, working van; leave when driving and stopped. True when the press was used.
static func press(world: RefCounted) -> bool:
	if driving(world):
		if absf(float(world.vehicle.speed)) > 5.0:
			world.note("Stop the van before getting out.")
		elif not leave(world):
			world.note("No clear ground beside the van. Move it and try again.")
		return true
	if not near(world):
		return false
	world.vehicle.driving = true
	world.vehicle.speed = 0.0
	world.working = false
	world.player.pos = pos(world)
	world.vehicle.riders = _passengers(world)
	_seat(world)
	var names: Array[String] = []
	for a: Dictionary in _riders(world):
		names.append(str(a.name))
	world.note("Driving%s. W/S throttle, A/D steer, E to get out." % ((" with " + " and ".join(names)) if not names.is_empty() else ""))
	return true


## Followers close enough to the van take its free seats, nearest first.
static func _passengers(world: RefCounted) -> Array:
	var config: Dictionary = world.catalog.vehicle
	var found: Array[Dictionary] = []
	for a: Dictionary in world.survivors:
		if float(a.hp) > 0 and a.order == "Follow" and a.pos.distance_to(pos(world)) <= float(config.board_range):
			found.append(a)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.distance_to(pos(world)) < b.pos.distance_to(pos(world)))
	var ids: Array = []
	for a: Dictionary in found.slice(0, int(config.seats)):
		ids.append(a.id)
	return ids


static func _riders(world: RefCounted) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for a: Dictionary in world.survivors:
		if world.vehicle.riders.has(a.id):
			found.append(a)
	return found


## Passengers sit at the van's centre and face its way, so zombies sense them where the hull is.
static func _seat(world: RefCounted) -> void:
	for a: Dictionary in _riders(world):
		a.pos = pos(world)
		a.facing = forward(float(world.vehicle.heading))
		a.activity = "Riding in the van"


## Clear standing places around the van, nearest first, for the driver and then each passenger.
static func _exits(world: RefCounted) -> Array[Vector2]:
	var config: Dictionary = world.catalog.vehicle
	var ahead: Vector2 = forward(float(world.vehicle.heading))
	var side: Vector2 = ahead.orthogonal()
	var reach: float = float(config.half_width) + float(config.exit_clearance)
	var end: float = float(config.half_length) + float(config.exit_clearance)
	var found: Array[Vector2] = []
	for offset: Vector2 in [side * reach, -side * reach, -ahead * end, ahead * end, side * reach * 1.8, -side * reach * 1.8, -ahead * end * 1.5, ahead * end * 1.5]:
		var point: Vector2 = pos(world) + offset
		if world.routes.walkable(point):
			found.append(point)
	return found


## Everyone is placed on distinct clear ground; a passenger is never dropped through a wall or lost.
static func _seat_out(world: RefCounted) -> void:
	var taken: Array[Vector2] = [world.player.pos]
	for a: Dictionary in _riders(world):
		var spot: Vector2 = world.player.pos + Vector2(12.0 * taken.size(), 8.0)
		for point: Vector2 in _exits(world):
			if taken.all(func(other: Vector2) -> bool: return other.distance_to(point) >= 18.0):
				spot = point
				break
		a.pos = spot
		a.activity = "Follow"
		taken.append(spot)
	world.vehicle.riders = []


static func leave(world: RefCounted) -> bool:
	var exits: Array[Vector2] = _exits(world)
	if exits.is_empty():
		return false
	world.player.pos = exits[0]
	world.vehicle.driving = false
	world.vehicle.speed = 0.0
	_seat_out(world)
	return true


static func context(world: RefCounted) -> String:
	if driving(world):
		var riding: String = " · %d riding" % world.vehicle.riders.size() if not world.vehicle.riders.is_empty() else ""
		return "E Get out   W/S drive  A/D steer   hull %d%s" % [int(world.vehicle.hull), riding]
	if not bool(world.vehicle.present) or world.player.pos.distance_to(pos(world)) > float(world.catalog.vehicle.enter_range):
		return ""
	var fix: String = _repair_prompt(world)
	if near(world):
		var cargo: String = " with " + str(Equipment.person(world, world.carry.patient).name) if not str(world.carry.patient).is_empty() else ""
		return "E Drive the van" + cargo + fix
	return "The van is wrecked" + fix if float(world.vehicle.hull) <= 0 else ""


static func _repair_prompt(world: RefCounted) -> String:
	var config: Dictionary = world.catalog.vehicle
	if float(world.vehicle.hull) >= float(config.hull):
		return ""
	if bool(world.vehicle.repair_paid):
		return "   Hold R Repair · %d%%" % int(100 * float(world.vehicle.repair_progress) / float(config.repair_seconds))
	if world.materials < int(config.repair_materials):
		return "   Repair needs %d materials" % int(config.repair_materials)
	return "   Hold R Repair · %d materials" % int(config.repair_materials)


## Hold R beside a stopped van to approve a repair; it is then a work-board project (see van_repair.gd).
static func repair(world: RefCounted, dt: float) -> void:
	VanRepair.step(world, dt)


static func step(world: RefCounted, dt: float) -> void:
	if not bool(world.vehicle.present) or not driving(world):
		return
	var state: Dictionary = world.vehicle
	var config: Dictionary = world.catalog.vehicle
	var throttle: float = -float(world.move_input.y)
	var steer: float = float(world.move_input.x)
	var speed: float = float(state.speed)
	var accel: float = float(config.accel) * dt
	var brake: float = float(config.brake) * dt
	if absf(throttle) < 0.1:
		speed = move_toward(speed, 0.0, brake)
	elif throttle > 0:
		speed = speed + (brake if speed < 0 else accel)
	else:
		speed = speed - (brake if speed > 0 else accel)
	speed = clampf(speed, -float(config.reverse), float(config.forward))
	var heading: float = float(state.heading)
	if absf(speed) > 1.0 and absf(steer) > 0.05:
		var turned: float = heading + steer * deg_to_rad(float(config.turn_degrees)) * dt * clampf(absf(speed) / 80.0, 0.0, 1.0) * signf(speed)
		if fits(world, pos(world), turned):
			heading = turned
	state.heading = heading
	# Short straight samples keep the swept footprint from tunnelling at full speed.
	var travel: float = absf(speed) * dt
	var direction: Vector2 = forward(heading) * signf(speed)
	var at: Vector2 = pos(world)
	while travel > 0.0001:
		var stride: float = minf(3.0, travel)
		if not fits(world, at + direction * stride, heading):
			speed = 0.0
			break
		at += direction * stride
		travel -= stride
	state.x = at.x
	state.y = at.y
	state.speed = speed
	world.player.pos = at
	world.player.facing = forward(heading)
	_seat(world)
	if absf(speed) > 1.0:
		Acoustics.emit(world, "van", "engine", at)
	_batter(world, at)


## Zombies at the hull attack it with their structure damage; the occupant is only exposed once it is wrecked.
static func _batter(world: RefCounted, at: Vector2) -> void:
	for z: Dictionary in world.zombies:
		if float(z.hp) > 0 and float(z.cooldown) <= 0 and z.pos.distance_to(at) < 46.0:
			var kind: Dictionary = world.catalog.zombies.types[z.get("kind", world.catalog.zombies.default)]
			hit(world, 7.0 * float(kind.breach))
			z.cooldown = float(kind.cooldown)


static func hit(world: RefCounted, damage: float) -> void:
	world.vehicle.hull = maxf(0.0, float(world.vehicle.hull) - damage)
	if float(world.vehicle.hull) <= 0 and driving(world):
		world.vehicle.speed = 0.0
		if not leave(world):
			world.vehicle.driving = false
			_seat_out(world)
		world.note("The van is wrecked. You climb out.")
