extends RefCounted
const Equipment = preload("res://scripts/sim/equipment.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Combat = preload("res://scripts/sim/combat.gd")


static func initial() -> Dictionary:
	return {"mode": "", "patients": {}}


static func present(world: RefCounted, a: Dictionary) -> bool:
	return a.id != world.carry.patient and Routes.rectangle(world.definition("home").rect).has_point(a.pos) and world.routes.walkable(a.pos)


static func safe(world: RefCounted) -> bool:
	return world.properties.home.claimed and world.remaining("home") == 0 and world.alert == "SAFE" and not Combat.danger(world, Routes.point(world.balance.home_alert_center), float(world.balance.home_alert_radius))


static func at_porch(world: RefCounted) -> bool:
	return world.player.pos.distance_to(Routes.point(world.definition("home").site)) < 85


static func ceiling(world: RefCounted, mode: String) -> float:
	return float(world.balance.home_recover_health) if mode == "recover" else float(world.balance.survivor_health)


static func next_mode(world: RefCounted) -> String:
	var injured: bool = false
	for a: Dictionary in [world.player] + world.survivors:
		if not present(world, a):
			continue
		if float(a.hp) < float(world.balance.home_recover_health):
			return "recover"
		injured = injured or float(a.hp) < float(world.balance.survivor_health)
	return "heal" if injured else ""


static func start(world: RefCounted) -> bool:
	if float(world.player.hp) <= 0 or not at_porch(world) or not safe(world) or not str(world.carry.patient).is_empty():
		world.note("Bring patients to the clear home shelter first.")
		return false
	if not world.home_rest.patients.is_empty():
		return false
	var mode: String = next_mode(world)
	if mode.is_empty():
		return false
	if world.food < int(world.balance.recovery_food):
		world.note("Need food for home rest.")
		return false
	var patients: Dictionary = {}
	for a: Dictionary in [world.player] + world.survivors:
		if present(world, a) and float(a.hp) < ceiling(world, mode):
			patients[a.id] = 0.0
	world.food -= int(world.balance.recovery_food)
	world.home_rest = {"mode": mode, "patients": patients}
	return true


static func step(world: RefCounted, dt: float) -> void:
	var s: Dictionary = world.home_rest
	if s.patients.is_empty():
		return
	var limit: float = ceiling(world, s.mode)
	for id: String in s.patients.keys():
		var a: Dictionary = Equipment.person(world, id)
		if float(a.hp) >= limit:
			s.patients.erase(id)
			continue
		if not safe(world) or not present(world, a):
			continue
		s.patients[id] = minf(float(world.balance.home_rest_seconds), float(s.patients[id]) + dt)
		if float(s.patients[id]) >= float(world.balance.home_rest_seconds):
			a.hp = maxf(float(a.hp), limit)
			s.patients.erase(id)
	if s.patients.is_empty():
		world.home_rest = initial()


static func context(world: RefCounted) -> String:
	if not world.home_rest.patients.is_empty():
		var progress: float = float(world.balance.home_rest_seconds)
		var found: bool = false
		for id: String in world.home_rest.patients:
			if present(world, Equipment.person(world, id)):
				found = true
				progress = minf(progress, float(world.home_rest.patients[id]))
		return "Rest · %d%%" % int(100 * progress / float(world.balance.home_rest_seconds)) if found else "Rest waiting"
	var mode: String = next_mode(world)
	return "" if mode.is_empty() else "E %s · %d food" % ["Recover" if mode == "recover" else "Heal", int(world.balance.recovery_food)]
