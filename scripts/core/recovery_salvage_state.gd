extends RefCounted
const Routes = preload("res://scripts/sim/routes.gd")
const Rules = preload("res://addons/hatchery/core/data_rules.gd")


static func content(data: Dictionary, errors: Array[String]) -> void:
	var rules := Rules.new(errors, "recovery salvage")
	if not rules.object(data, "recovery_salvage"):
		return
	var c: Dictionary = data.recovery_salvage
	if not Rules.integer_in(c.get("cap"), 24, 1000) or not Rules.integer_in(c.get("batch"), 1, 24):
		errors.append("Recovery salvage needs a usable whole cap and output.")
	rules.number_between(c, "seconds", 1, 1000)
	rules.number_between(c, "range", 10, 60)
	if not rules.object(c, "sites"):
		return
	if c.sites.keys() != ["home", "west"]:
		errors.append("Recovery salvage needs the implemented home and west piles.")
	for id: String in c.sites:
		rules.vec2(c.sites, id)
	if not Rules.is_vec2(c.sites.get("home")) or not Rules.is_vec2(c.sites.get("west")):
		return
	var home: Rect2 = Routes.rectangle(_home(data).rect)
	if not home.has_point(Routes.point(c.sites.home)) or _in_lot(data, Routes.point(c.sites.west)) or Routes.point(c.sites.west).distance_to(home.get_center()) > 700:
		errors.append("Recovery piles need a home-yard pile and a pile on open road near home.")


static func _home(data: Dictionary) -> Dictionary:
	for p: Dictionary in data.properties:
		if p.id == "home":
			return p
	return {}


static func _in_lot(data: Dictionary, point: Vector2) -> bool:
	for p: Dictionary in data.properties:
		if Routes.rectangle(p.rect).has_point(point):
			return true
	return false


static func valid(data: Dictionary, catalog: Dictionary) -> bool:
	var s: Variant = data.get("recovery_salvage")
	if not s is Dictionary or s.size() != 2 or not s.has("home") or not s.has("west"):
		return false
	for value: Variant in s.values():
		if not Rules.finite(value) or float(value) < 0 or float(value) >= float(catalog.recovery_salvage.seconds):
			return false
	return true
