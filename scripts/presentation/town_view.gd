extends Node2D
## Original procedural greybox art. No imported game assets.
const Firearms = preload("res://scripts/sim/firearms.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const NeighbourhoodView = preload("res://scripts/presentation/neighbourhood_view.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const RoadView = preload("res://scripts/presentation/road_view.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var world: RefCounted
var font: Font = ThemeDB.fallback_font
const INK := Color("142426")
const CREAM := Color("e7dfbf")
const TEAL := Color("9dceb3")
const RUST := Color("d88c63")


func _draw() -> void:
	if world == null:
		return
	draw_rect(Rect2(0, 0, int(world.catalog.bounds[0]), 1160), Color("293a34"))
	for x: int in range(0, int(world.catalog.bounds[0]), 32):
		for y: int in range(0, 1160, 32):
			var shade: float = float((x * 7 + y * 13) % 23) / 300.0
			draw_rect(Rect2(x + 2, y + 2, 28, 28), Color(0.16 + shade, 0.22 + shade, 0.18 + shade))
	draw_rect(Rect2(0, 500, int(world.catalog.bounds[0]), 160), Color("353e3e"))
	# The two exposed alleys feed the road between the property blocks.
	draw_rect(Rect2(660, 0, 120, 500), Color("45473d"))
	draw_rect(Rect2(660, 660, 120, 500), Color("45473d"))
	draw_rect(Rect2(0, 500, int(world.catalog.bounds[0]), 7), Color("7b8174"))
	draw_rect(Rect2(0, 653, int(world.catalog.bounds[0]), 7), Color("7b8174"))
	for x: int in range(0, int(world.catalog.bounds[0]), 100):
		draw_rect(Rect2(x + 10, 577, 50, 5), Color("ada47b"))
	for p: Dictionary in world.catalog.properties:
		_property(p)
	NeighbourhoodView.paint(self, world)
	RoadView.paint(self, world, font)
	# Characters are sorted by their feet, including bodies on the ground.
	var actors: Array = [world.player] + world.survivors + world.zombies
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.y < b.pos.y)
	for a: Dictionary in actors:
		_actor(a, a.has("raid"))
	if float(world.shot.left) > 0:
		draw_line(world.shot.from, world.shot.to, Color("ffe7a0"), 3)
		draw_circle(world.shot.from, 9, Color("fff0b0"))


func _property(p: Dictionary) -> void:
	var state: Dictionary = world.properties[p.id]
	var rect: Rect2 = Routes.rectangle(p.rect)
	var building: Rect2 = Routes.rectangle(p.building)
	var site: Vector2 = Routes.point(p.site)
	var gate: Vector2 = Routes.point(p.gate)
	var accent: Color = TEAL if state.claimed else RUST
	draw_rect(rect.grow(-8), Color("35463b") if state.claimed else Color("3d4035"))
	# Worn path joins each porch to the physical entrance.
	draw_line(site, gate, Color("686855"), 44)
	for i: int in range(7):
		var pos: Vector2 = site.lerp(gate, float(i) / 6.0)
		draw_line(pos + Vector2(-16, 0), pos + Vector2(16, 0), Color("79745d"), 2)
	# Drop shadow, timber siding, roof planes and boarded windows.
	draw_rect(Rect2(building.position + Vector2(8, 12), building.size), Color(0, 0, 0, 0.25))
	draw_rect(building, Color("5d6557") if state.claimed else Color("626052"))
	for y: int in range(int(building.position.y) + 10, int(building.end.y), 12):
		draw_line(Vector2(building.position.x, y), Vector2(building.end.x, y), Color("454d43"), 2)
	var roof := Rect2(building.position - Vector2(10, 12), Vector2(building.size.x + 20, 92))
	draw_rect(roof, Color("394b4b") if p.id in ["home", "library"] else Color("604d42"))
	for x: int in range(int(roof.position.x), int(roof.end.x), 26):
		draw_line(Vector2(x, roof.position.y), Vector2(x, roof.end.y), Color("243638"), 2)
	draw_line(roof.position, Vector2(roof.end.x, roof.position.y), accent.darkened(0.35), 5)
	for x: float in [building.position.x + 35, building.end.x - 75]:
		var window := Rect2(x, building.end.y - 52, 40, 30)
		draw_rect(window.grow(3), INK)
		draw_rect(window, Color("cdb46b") if state.claimed else Color("253538"))
		if not state.claimed:
			draw_line(window.position, window.end, Color("9b8764"), 6)
	draw_rect(Rect2(building.get_center().x - 18, building.end.y - 48, 36, 48), Color("263536"))
	_fence(rect, gate, state, accent)
	# Only nearby porches need a prompt; ownership is visible in flags and windows.
	if world.player.pos.distance_to(site) < 85:
		draw_circle(site, 23, Color(0.06, 0.12, 0.12, 0.8))
		draw_arc(site, 23, 0, TAU, 24, accent, 2)
		_text(site + Vector2(-5, 6), "E", 18, accent)
	if state.claimed and world.timber.has(p.id) and not world.timber[p.id]:
		for i: int in range(3):
			draw_line(site + Vector2(-92, 16 + i * 7), site + Vector2(-48, 16 + i * 7), Color("ab8860"), 5)
	if p.id == "home":
		_meter(gate + Vector2(-44, 20), 88, float(state.gate_hp) / float(world.balance.gate_health), accent)
	if p.id == "garden":
		_garden(rect, site)
	if p.id == "munitions" and state.claimed:
		draw_rect(Rect2(site + Vector2(65, 0), Vector2(80, 25)), Color("ab8860"))
		for i: int in range(6):
			draw_line(site + Vector2(75 + i * 10, 3), site + Vector2(75 + i * 10, 18), Color("dfb36e"), 4)
		_meter(site + Vector2(65, 33), 80, Firearms.progress(world) / float(world.catalog.firearm.craft_seconds), TEAL)
	if p.id == "garage":
		_workshop(site)
	if float(state.occupation) > 0:
		_meter(site + Vector2(-44, 48), 88, 1.0 - float(state.occupation) / float(world.balance.territory_fall_seconds), RUST)
	if state.claimed:
		draw_line(site + Vector2(48, -10), site + Vector2(48, 35), CREAM, 3)
		draw_colored_polygon(PackedVector2Array([site + Vector2(49, -10), site + Vector2(75, -10), site + Vector2(49, 8)]), TEAL)


func _fence(rect: Rect2, gate: Vector2, state: Dictionary, accent: Color) -> void:
	var top: bool = gate.y == rect.position.y
	for y: float in [rect.position.y, rect.end.y]:
		var opening: bool = (top and y == rect.position.y) or (not top and y == rect.end.y)
		if opening:
			draw_line(Vector2(rect.position.x, y), Vector2(gate.x - 44, y), Color("968168"), 7)
			draw_line(Vector2(gate.x + 44, y), Vector2(rect.end.x, y), Color("968168"), 7)
		else:
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("968168"), 7)
	for x: float in [rect.position.x, rect.end.x]:
		var opening := Rect2()
		for area: Rect2 in Neighbourhood.openings(world):
			if area.intersects(Rect2(x - 8, rect.position.y, 16, rect.size.y)):
				opening = area
		if opening.has_area():
			draw_line(Vector2(x, rect.position.y), Vector2(x, opening.position.y), Color("968168"), 7)
			draw_line(Vector2(x, opening.end.y), Vector2(x, rect.end.y), Color("968168"), 7)
		else:
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("968168"), 7)
		for y: int in range(int(rect.position.y), int(rect.end.y) + 1, 40):
			if not opening.has_area() or y < opening.position.y or y > opening.end.y:
				draw_rect(Rect2(x - 6, y - 6, 12, 12), Color("b09a75"))
	if float(state.gate_hp) > 0:
		var end: Vector2 = gate + (Vector2(-44, -60) if state.open else Vector2(44, 0))
		draw_line(gate - Vector2(44, 0), end, accent.darkened(0.2), 9)
		draw_line(gate - Vector2(44, 0), end, accent, 2)


func _garden(rect: Rect2, site: Vector2) -> void:
	if world.garden_started:
		for row: int in range(3):
			var origin: Vector2 = Vector2(rect.position.x + 48, site.y - 14 + row * 30)
			draw_rect(Rect2(origin, Vector2(120, 22)), Color("594937"))
			for col: int in range(6):
				var plant: Vector2 = origin + Vector2(10 + col * 20, 11)
				if world.garden_done:
					draw_line(plant + Vector2(-5, -5), plant + Vector2(5, 5), TEAL, 4)
					draw_line(plant + Vector2(5, -5), plant + Vector2(-5, 5), Color("698e50"), 4)
		if not world.garden_done:
			_meter(site + Vector2(-60, 36), 120, float(world.garden_progress) / float(world.balance.work_seconds), TEAL)



func _actor(a: Dictionary, zombie: bool) -> void:
	var pos: Vector2 = a.pos
	var direction: Vector2 = a.facing
	if float(a.hp) <= 0:
		draw_line(pos - Vector2(12, 0), pos + Vector2(12, 0), Color("575e4d") if zombie else RUST, 9)
		return
	_ellipse(pos + Vector2(1, 4), Vector2(21, 9) if a.get("kind") == "brute" else Vector2(15, 7), Color(0, 0, 0, 0.3))
	var body: Color = (Color("8a5a4a") if a.get("kind") == "brute" else Color("788357")) if zombie else (Color("dfad62") if a.id == "you" else (Color("7daeb9") if a.id == "mara" else (Color("91b69e") if a.id == "ellis" else Color("b7a0c8"))))
	if float(a.flash) > 0:
		body = Color("fff0d5")
	draw_line(pos + Vector2(-5, -3), pos + Vector2(-6, 3), INK, 5)
	draw_line(pos + Vector2(5, -3), pos + Vector2(6, 3), INK, 5)
	draw_rect(Rect2(pos + Vector2(-10, -22), Vector2(20, 20)), body)
	draw_rect(Rect2(pos + Vector2(-10, -10), Vector2(20, 4)), body.darkened(0.3))
	_head(pos + Vector2(0, -29), direction, zombie)
	if not zombie and Equipment.protected(world, a):
		_armour(pos, a.facing)
	if not zombie and Equipment.shielded(world, a):
		_shield(pos, a.facing)
	if not zombie and a.id != "ellis" and not (a.id == "you" and float(world.shot.left) > 0):
		var grip: Vector2 = pos + Vector2(0, -14) + direction * 12
		var weapon: String = Equipment.weapon(world, a)
		draw_line(grip, grip + direction * (36 if weapon == "sword" else 27), Color("c7b68e") if weapon == "bat" else Color("c1d1d0"), 5 if weapon != "sword" else 3)
		if weapon == "crowbar":
			draw_line(grip + direction * 27, grip + direction * 27 + direction.orthogonal() * 10, Color("c1d1d0"), 4)
		draw_circle(grip, 3, Color("d7b08b"))
		if a.id != "you" and a.pos.distance_to(world.player.pos) < 170:
			_text(pos + Vector2(-16, -49), a.name, 13, CREAM)
	if a.id == "ellis" and a.pos.distance_to(world.player.pos) < 170:
		_text(pos + Vector2(-16, -49), "Ellis", 13, CREAM)
	if a.id == "you" and float(world.shot.left) > 0:
		draw_line(pos + direction * 12, pos + direction * 32, INK, 7)
	if float(a.swing) > 0:
		var stats: Dictionary = Equipment.stats(world, a)
		var half_angle: float = acos(float(stats.cone))
		draw_arc(pos, float(stats.reach), direction.angle() - half_angle, direction.angle() + half_angle, 24, CREAM, 3)
	if float(a.hp) < (ZombieTypes.full_health(world.catalog, a) if zombie else 100.0):
		_meter(pos + Vector2(-15, 10), 30, float(a.hp) / (ZombieTypes.full_health(world.catalog, a) if zombie else 100.0), RUST)


func _head(center: Vector2, direction: Vector2, zombie: bool) -> void:
	var skin := Color("9caa73") if zombie else Color("d7b08b")
	draw_circle(center, 8, skin)
	# Hair sits behind the gaze, rather than making every head face down.
	draw_arc(center, 8, direction.angle() + PI / 2, direction.angle() + PI * 1.5, 12, INK, 5)
	var side := Vector2(-direction.y, direction.x)
	for sign: float in [-1.0, 1.0]:
		draw_circle(center + direction * 4 + side * sign * 3, 1.3, INK)
	draw_circle(center + direction * 8, 2, skin.lightened(0.15))


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in range(20):
		points.append(center + Vector2(cos(i * TAU / 20), sin(i * TAU / 20)) * radius)
	draw_colored_polygon(points, color)


func _meter(pos: Vector2, width: float, fraction: float, color: Color) -> void:
	draw_rect(Rect2(pos - Vector2(1, 1), Vector2(width + 2, 7)), INK)
	draw_rect(Rect2(pos, Vector2(width * clampf(fraction, 0, 1), 5)), color)


func _text(pos: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _workshop(site: Vector2) -> void:
	var state: Dictionary = world.workshop
	var bench: Vector2 = site + Vector2(84, 10)
	draw_rect(Rect2(bench + Vector2(-5, -4), Vector2(80, 32)), INK)
	draw_rect(Rect2(bench, Vector2(70, 18)), Color("ab8860") if state.done else Color("655b4b"))
	for x: float in [4, 60]:
		draw_line(bench + Vector2(x, 18), bench + Vector2(x, 30), Color("847b66"), 5)
	if state.done:
		draw_line(bench + Vector2(10, 6), bench + Vector2(28, 6), CREAM, 4)
		draw_circle(bench + Vector2(31, 6), 5, Color("a9b7b5"))
	if world.properties.garage.claimed and world.equipment.iron.is_empty():
		# The unique recovered set remains physically visible until fitted.
		draw_rect(Rect2(bench + Vector2(39, -3), Vector2(18, 23)), Color("c1d1d0") if state.armour_done else Color("837f71"))
		draw_arc(bench + Vector2(48, -6), 7, PI, TAU, 12, CREAM, 3)
	if state.started and not state.done:
		_meter(site + Vector2(-60, 36), 120, float(state.progress) / float(world.balance.workshop_seconds), TEAL)
	elif state.armour_started and not state.armour_done:
		_meter(site + Vector2(-60, 36), 120, float(state.armour_progress) / float(world.balance.armour_seconds), TEAL)


func _armour(pos: Vector2, facing: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-11, -22), Vector2(22, 20)), Color("b7c8ca"))
	draw_line(pos + Vector2(0, -20), pos + Vector2(0, -4), Color("718c92"), 3)
	draw_line(pos + Vector2(-13, -21), pos + Vector2(13, -21), CREAM, 4)
	draw_arc(pos + Vector2(0, -29), 10, PI, TAU, 12, Color("b7c8ca"), 5)
	# Keep Paige's purple scarf and face visible through the iron silhouette.
	draw_line(pos + Vector2(-8, -22), pos + Vector2(8, -22), Color("b7a0c8"), 4)


func _shield(pos: Vector2, facing: Vector2) -> void:
	var shield: Vector2 = pos + facing * 17 + Vector2(-8, -12)
	draw_circle(shield, 12, INK)
	draw_circle(shield, 10, Color("a8babe"))
	draw_line(shield + Vector2(-7, 0), shield + Vector2(7, 0), CREAM, 3)
