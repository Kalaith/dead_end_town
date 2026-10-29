extends RefCounted
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	if not data.get("balance") is Dictionary:
		return
	var rules := Rules.new(errors, "recovery")
	for key: String in ["carry_range", "carry_seconds", "home_rest_seconds"]:
		rules.number_between(data.balance, key, 0.01, 1000)
	rules.vec2(data.balance, "emergency_shelter")
	if Rules.is_vec2(data.balance.get("emergency_shelter")):
		var point: Array = data.balance.emergency_shelter
		var spot := Vector2(float(point[0]), float(point[1]))
		var near_home: bool = false
		var inside_lot: bool = false
		for p: Dictionary in data.get("properties", []):
			var rect := Rect2(float(p.rect[0]), float(p.rect[1]), float(p.rect[2]), float(p.rect[3]))
			inside_lot = inside_lot or rect.has_point(spot)
			near_home = near_home or (p.id == "home" and rect.get_center().distance_to(spot) <= 700)
		if inside_lot or not near_home:
			errors.append("Emergency shelter must stay on open road within reach of home.")
	for key: String in ["defeat_player_health", "defeat_survivor_health"]:
		rules.number_between(data.balance, key, 1, 100)
	for key: String in ["recovery_clear_radius", "recovery_relocate_distance", "recovery_migration_seconds"]:
		rules.number_between(data.balance, key, 1, 1000)
	rules.number_between(data.balance, "carry_speed_factor", 0.01, 1.0)
	rules.number_between(data.balance, "home_recover_health", 1.0, 100.0)


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("defeat_pending") is bool or (data.defeat_pending and float(data.player.hp) > 0):
		return false
	var ids: Array[String] = []
	var actors: Dictionary = {"you": data.player}
	for a: Dictionary in data.survivors:
		ids.append(a.id)
		actors[a.id] = a
	var c: Variant = data.get("carry")
	if not c is Dictionary or not c.get("patient") is String or not c.get("target") is String or not Rules.finite(c.get("progress")):
		return false
	if float(c.progress) < 0 or float(c.progress) >= float(catalog.balance.carry_seconds):
		return false
	for key: String in ["patient", "target"]:
		if not c[key].is_empty() and (c[key] not in ids or float(actors[c[key]].hp) > 0):
			return false
	if not c.patient.is_empty():
		if not c.target.is_empty() or float(c.progress) != 0 or actors[c.patient].pos != data.player.pos:
			return false
	if c.target.is_empty() and float(c.progress) != 0:
		return false
	var s: Variant = data.get("home_rest")
	if not s is Dictionary or s.get("mode") not in ["", "recover", "heal"] or not s.get("patients") is Dictionary:
		return false
	if s.mode.is_empty() != s.patients.is_empty():
		return false
	for id: Variant in s.patients:
		if id not in actors or not Rules.finite(s.patients[id]) or float(s.patients[id]) < 0 or float(s.patients[id]) >= float(catalog.balance.home_rest_seconds):
			return false
	return true
