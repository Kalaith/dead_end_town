extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")
const Facility = preload("res://scripts/sim/facility.gd")


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("rescue_jobs") is Dictionary:
		return false
	var actors: Dictionary = {}
	for a: Dictionary in data.survivors:
		actors[a.id] = a
	var patients: Array[String] = []
	if not str(data.carry.patient).is_empty():
		patients.append(data.carry.patient)
	for id: Variant in data.rescue_jobs:
		var job: Variant = data.rescue_jobs[id]
		if id not in actors or not job is Dictionary or not job.get("patient") is String or job.patient not in actors or job.patient == id or job.patient in patients:
			return false
		var a: Dictionary = actors[id]
		var patient: Dictionary = actors[job.patient]
		if a.order != "Rescue" or a.job != job.patient or float(a.hp) <= 0 or float(patient.hp) > 0 or not a.get("duty") is Dictionary or a.duty.get("temporary") != true:
			return false
		if job.get("shelter") not in ["home", "clinic"] or not Facility.saved(data, catalog, str(job.shelter)).looted or job.get("phase") not in ["approach", "lift", "carry"]:
			return false
		if not Rules.finite(job.get("progress")) or float(job.progress) < 0 or float(job.progress) >= float(catalog.balance.carry_seconds):
			return false
		if job.phase != "lift" and float(job.progress) != 0:
			return false
		if job.phase == "carry" and patient.pos != a.pos:
			return false
		patients.append(job.patient)
	for a: Dictionary in data.survivors:
		if a.order == "Rescue" and not data.rescue_jobs.has(a.id):
			return false
	return true
