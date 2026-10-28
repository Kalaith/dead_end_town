extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const Combat = preload("res://scripts/sim/combat.gd")


static func owner(world: RefCounted, patient: String) -> String:
	if world.carry.patient == patient:
		return "you"
	for id: String in world.rescue_jobs:
		if world.rescue_jobs[id].patient == patient:
			return id
	return ""


static func destination(world: RefCounted, patient: Dictionary) -> String:
	var selected: String = ""
	var distance: float = INF
	for id: String in ["home", "clinic"]:
		if id == "clinic" and (not world.clinic.done or world.medicine <= 0):
			continue
		var site: Vector2 = Routes.point(world.definition(id).site)
		if not world.safe_connected(id) or world.remaining(id) > 0 or Combat.danger(world, site, 170):
			continue
		var next: float = patient.pos.distance_squared_to(site)
		if next < distance:
			selected = id
			distance = next
	return selected


static func reason(world: RefCounted, patient_id: String, carrier: Dictionary = {}) -> String:
	var patient: Dictionary = Equipment.person(world, patient_id)
	if patient.is_empty() or patient_id == "you" or float(patient.hp) > 0:
		return "Need a downed survivor"
	var existing: String = owner(world, patient_id)
	if not existing.is_empty() and (carrier.is_empty() or existing != carrier.id):
		return "Already being rescued"
	if not carrier.is_empty() and (carrier.id == patient_id or float(carrier.hp) <= 0):
		return "Need a standing carrier"
	if Combat.danger(world, patient.pos, 170) or (not carrier.is_empty() and Combat.danger(world, carrier.pos, 170)):
		return "Clear nearby threats"
	var shelter: String = destination(world, patient)
	if shelter.is_empty():
		return "Secure a protected shelter route"
	if shelter == "home" and Routes.rectangle(world.definition("home").rect).has_point(patient.pos):
		return "Already at home"
	if shelter == "clinic" and patient.pos.distance_to(Routes.point(world.definition("clinic").site)) < 70:
		return "Already at clinic"
	return ""


static func waypoint(world: RefCounted, from: Vector2, to: Vector2) -> Vector2:
	var areas: Array[Rect2] = Neighbourhood.work_areas(world)
	return to if world.routes.safe_travel_clear(from, to, areas) else world.routes.safe_waypoint(from, to, areas)


static func can_reach(world: RefCounted, from: Vector2, to: Vector2) -> bool:
	var areas: Array[Rect2] = Neighbourhood.work_areas(world)
	return world.routes.safe_travel_clear(from, to, areas) or not world.routes.safe_waypoint(from, to, areas).is_equal_approx(from)


static func assignment_reason(world: RefCounted, a: Dictionary, patient_id: String) -> String:
	var why: String = reason(world, patient_id, a)
	if not why.is_empty():
		return why
	var patient: Dictionary = Equipment.person(world, patient_id)
	var shelter: String = destination(world, patient)
	if not can_reach(world, a.pos, patient.pos) or not can_reach(world, patient.pos, Routes.point(world.definition(shelter).site)):
		return "No protected rescue route. The casualty stays in place"
	return ""


static func start(world: RefCounted, a: Dictionary, patient_id: String) -> void:
	var patient: Dictionary = Equipment.person(world, patient_id)
	world.rescue_jobs[a.id] = {"patient": patient_id, "shelter": destination(world, patient), "phase": "approach", "progress": 0.0}
	a.order = "Rescue"
	a.job = patient_id
	a.anchor = patient.pos


static func release(world: RefCounted, a: Dictionary, resume: bool = true) -> void:
	if not world.rescue_jobs.has(a.id):
		return
	var job: Dictionary = world.rescue_jobs[a.id]
	if job.phase == "carry":
		Equipment.person(world, job.patient).pos = a.pos
	world.rescue_jobs.erase(a.id)
	a.order = "Idle"
	a.job = ""
	a.anchor = a.pos
	if resume and float(a.hp) > 0:
		world.finish_job(a)


static func cancel_all(world: RefCounted) -> void:
	for id: String in world.rescue_jobs.keys():
		release(world, Equipment.person(world, id))


static func sync(world: RefCounted) -> void:
	for id: String in world.rescue_jobs.keys():
		var a: Dictionary = Equipment.person(world, id)
		var job: Dictionary = world.rescue_jobs[id]
		if float(a.hp) <= 0 or float(Equipment.person(world, job.patient).hp) > 0 or world.carry.patient == job.patient:
			release(world, a)
		elif job.phase == "carry":
			Equipment.person(world, job.patient).pos = a.pos


static func step(world: RefCounted, dt: float) -> void:
	for id: String in world.rescue_jobs.keys():
		var a: Dictionary = Equipment.person(world, id)
		var job: Dictionary = world.rescue_jobs[id]
		var patient: Dictionary = Equipment.person(world, job.patient)
		if float(a.hp) <= 0 or float(patient.hp) > 0 or world.carry.patient == patient.id:
			release(world, a)
			continue
		if Combat.danger(world, a.pos, 170) or Combat.danger(world, patient.pos, 170):
			if job.phase == "lift":
				job.phase = "approach"
				job.progress = 0.0
			a.duty.clear_left = float(world.balance.work_clear_seconds)
			a.activity = "Danger · rescue paused"
			continue
		if a.duty.clear_left > 0 or a.duty.retry > 0:
			continue
		var target: Vector2 = patient.pos if job.phase != "carry" else Routes.point(world.definition(job.shelter).site)
		if not world.safe_connected(job.shelter) or world.remaining(job.shelter) > 0 or (job.phase == "carry" and Combat.danger(world, target, 170)):
			a.activity = "Protect the shelter route"
			a.duty.retry = float(world.balance.work_retry_seconds)
			continue
		if job.phase == "carry" and a.pos.distance_to(target) < 24:
			release(world, a)
			continue
		if job.phase != "carry" and a.pos.distance_to(patient.pos) < float(world.balance.carry_range) and world.routes.line_clear(a.pos, patient.pos):
			if not can_reach(world, patient.pos, Routes.point(world.definition(job.shelter).site)):
				a.activity = "No protected rescue route"
				a.duty.retry = float(world.balance.work_retry_seconds)
				continue
			job.phase = "lift"
			job.progress = minf(float(world.balance.carry_seconds), float(job.progress) + dt)
			a.activity = "Lifting · %d%%" % int(100 * float(job.progress) / float(world.balance.carry_seconds))
			if job.progress >= float(world.balance.carry_seconds):
				job.phase = "carry"
				job.progress = 0.0
				patient.pos = a.pos
			continue
		var next: Vector2 = waypoint(world, a.pos, target)
		if next.is_equal_approx(a.pos):
			a.activity = "No protected rescue route"
			a.duty.retry = float(world.balance.work_retry_seconds)
			continue
		var speed: float = float(world.balance.survivor_speed) * Equipment.speed(world, a) * (float(world.balance.carry_speed_factor) if job.phase == "carry" else 1.0)
		a.facing = a.pos.direction_to(next)
		a.pos = world.routes.move(a.pos, next, speed * dt)
		a.activity = "Carrying to shelter" if job.phase == "carry" else "Reaching casualty"
	sync(world)
