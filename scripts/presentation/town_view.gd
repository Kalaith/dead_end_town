extends Node2D
## Original procedural greybox art. No imported game assets.
const GreenhouseView = preload("res://scripts/presentation/greenhouse_view.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const FieldMedicine = preload("res://scripts/sim/field_medicine.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const NeighbourhoodView = preload("res://scripts/presentation/neighbourhood_view.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const RoadView = preload("res://scripts/presentation/road_view.gd")
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var visible_world: Rect2
var world: RefCounted
var font: Font = ThemeDB.fallback_font
const INK := Color("142426")
const CREAM := Color("e7dfbf")
const Access = preload("res://scripts/presentation/access.gd")
## Held/healthy and threat colours come from the accessibility palette.
var TEAL: Color:
	get:
		return Access.good()
var RUST: Color:
	get:
		return Access.threat()


## Streets are authored rectangles. Alleys are plain, roads get kerbs and a centre line, and a plaza is a round
## junction with a planted island. Kerbs go down first so where roads meet they join without a wall line.
func _streets() -> void:
	var roads: Array[Rect2] = []
	var bridges: Array[Rect2] = []
	var plazas: Array[Rect2] = []
	for street: Dictionary in world.catalog.town.streets:
		var rect: Rect2 = Routes.rectangle(street.rect)
		if not rect.intersects(visible_world):
			continue
		if street.kind == "alley":
			draw_rect(rect, Color("45473d"))
		elif street.kind == "road":
			roads.append(rect)
		elif street.kind == "bridge":
			bridges.append(rect)
		else:
			plazas.append(rect)
	for rect: Rect2 in roads:
		draw_rect(rect, Color("7b8174"))
	for rect: Rect2 in roads:
		draw_rect(rect.grow(-7), Color("353e3e"))
	for rect: Rect2 in plazas:
		_plaza(rect)
	for rect: Rect2 in bridges:
		_bridge(rect)
	for rect: Rect2 in roads:
		if rect.size.x >= rect.size.y:
			for x: int in range(int(rect.position.x), int(rect.end.x) - 70, 100):
				_dash(Rect2(x + 10, rect.get_center().y - 3, 50, 5), plazas)
		else:
			for y: int in range(int(rect.position.y), int(rect.end.y) - 70, 100):
				_dash(Rect2(rect.get_center().x - 3, y + 10, 5, 50), plazas)


## A wide deck over the water: stone parapets down both sides, lane paint, and expansion joints across it.
func _bridge(rect: Rect2) -> void:
	draw_rect(rect, Color("7b8174"))
	draw_rect(Rect2(rect.position + Vector2(14, 0), rect.size - Vector2(28, 0)), Color("353e3e"))
	for y: int in range(int(rect.position.y) + 60, int(rect.end.y), 120):
		draw_rect(Rect2(rect.position.x + 14, y, rect.size.x - 28, 4), Color("2b3333"))
	for lane: float in [0.33, 0.67]:
		for y: int in range(int(rect.position.y), int(rect.end.y) - 70, 100):
			draw_rect(Rect2(rect.position.x + rect.size.x * lane - 3, y + 10, 5, 50), Color("ada47b"))
	for y: int in range(int(rect.position.y) + 20, int(rect.end.y), 90):
		for x: float in [rect.position.x + 3, rect.end.x - 11]:
			draw_rect(Rect2(x, y, 8, 40), Color("9aa092"))


func _water() -> void:
	for raw: Array in world.catalog.get("terrain", {}).get("water", []):
		var rect: Rect2 = Routes.rectangle(raw)
		if not rect.intersects(visible_world):
			continue
		draw_rect(rect, Color("1f3a4a"))
		for x: int in range(maxi(int(rect.position.x), floori(visible_world.position.x / 90) * 90), mini(int(rect.end.x), ceili(visible_world.end.x / 90) * 90), 90):
			for y: int in range(maxi(int(rect.position.y), floori(visible_world.position.y / 60) * 60), mini(int(rect.end.y), ceili(visible_world.end.y / 60) * 60), 60):
				var shift: int = (x * 7 + y * 3) % 40
				draw_line(Vector2(x + shift, y + 20), Vector2(x + shift + 26, y + 20), Color("2d5568"), 3)


## Centre-line paint stops at a plaza instead of crossing its planted island.
func _dash(dash: Rect2, plazas: Array[Rect2]) -> void:
	for plaza: Rect2 in plazas:
		if plaza.get_center().distance_to(dash.get_center()) < minf(plaza.size.x, plaza.size.y) / 2.0:
			return
	draw_rect(dash, Color("ada47b"))


func _plaza(rect: Rect2) -> void:
	var centre: Vector2 = rect.get_center()
	var radius: float = minf(rect.size.x, rect.size.y) / 2.0
	draw_circle(centre, radius, Color("7b8174"))
	draw_circle(centre, radius - 7, Color("353e3e"))
	draw_circle(centre, radius * 0.45, Color("7b8174"))
	draw_circle(centre, radius * 0.45 - 7, Color("3b5a43"))


func _draw() -> void:
	if world == null:
		return
	visible_world = Rect2(get_canvas_transform().affine_inverse() * Vector2.ZERO, get_viewport_rect().size)
	var width: int = int(world.catalog.bounds[0])
	var height: int = int(world.catalog.bounds[1])
	draw_rect(Rect2(0, 0, width, height), Color("293a34"))
	for x: int in range(maxi(0, floori(visible_world.position.x / 32) * 32), mini(width, ceili(visible_world.end.x / 32) * 32), 32):
		for y: int in range(maxi(0, floori(visible_world.position.y / 32) * 32), mini(height, ceili(visible_world.end.y / 32) * 32), 32):
			var shade: float = float((x * 7 + y * 13) % 23) / 300.0
			draw_rect(Rect2(x + 2, y + 2, 28, 28), Color(0.16 + shade, 0.22 + shade, 0.18 + shade))
	_water()
	_streets()
	_exit()
	_entrance()
	for p: Dictionary in world.catalog.properties:
		if Routes.rectangle(p.rect).grow(100).intersects(visible_world):
			_property(p)
	_caches()
	_spits()
	_vehicle()
	var shelter: Vector2 = Routes.point(world.balance.emergency_shelter)
	draw_rect(Rect2(shelter + Vector2(-24, -54), Vector2(48, 14)), Color("394b4b"))
	for x: int in [-18, 18]:
		draw_line(shelter + Vector2(x, -40), shelter + Vector2(x, -12), Color("ab8860"), 4)
	draw_rect(Rect2(shelter + Vector2(-16, -22), Vector2(32, 8)), Color("ab8860"))
	for id: String in world.catalog.recovery_salvage.sites:
		var scrap: Vector2 = Routes.point(world.catalog.recovery_salvage.sites[id])
		for i: int in range(3):
			draw_line(scrap + Vector2(-16 + i * 3, -4 + i * 5), scrap + Vector2(14 - i * 3, -9 + i * 5), Color("ab8860") if i != 1 else Color("9aa9a0"), 5)
		if float(world.recovery_salvage[id]) > 0:
			_meter(scrap + Vector2(-18, 16), 36, float(world.recovery_salvage[id]) / float(world.catalog.recovery_salvage.seconds), TEAL)
	NeighbourhoodView.paint(self, world)
	RoadView.paint(self, world, font)
	# Characters are sorted by their feet, including bodies on the ground.
	var actors: Array = [world.player] + world.survivors + world.zombies
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.y < b.pos.y)
	for a: Dictionary in actors:
		if visible_world.grow(100).has_point(a.pos):
			_actor(a, a.has("raid"))
	_casualty_marks()
	var patient: Dictionary = FieldMedicine.player_target(world)
	if not patient.is_empty():
		draw_arc(patient.pos, 25, 0, TAU, 32, Color("9dc1ce"), 2)
		if world.field_care.has(patient.id):
			draw_arc(patient.pos, 28, -PI / 2, -PI / 2 + TAU * float(world.field_care[patient.id]) / float(world.balance.field_seconds), 32, CREAM, 3)
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
	if p.facility == "greenhouse":
		GreenhouseView.building(self, building)
	else:
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
	if p.available and world.player.pos.distance_to(site) < 85 and not Carrying.occupied(world) and Carrying.nearby(world).is_empty():
		draw_circle(site, 23, Color(0.06, 0.12, 0.12, 0.8))
		draw_arc(site, 23, 0, TAU, 24, accent, 2)
		_text(site + Vector2(-5, 6), "E", 18, accent)
	if state.claimed and world.timber.has(p.id) and not world.timber[p.id]:
		for i: int in range(3):
			draw_line(site + Vector2(-92, 16 + i * 7), site + Vector2(-48, 16 + i * 7), Color("ab8860"), 5)
	if p.id == "home":
		_meter(gate + Vector2(-44, 20), 88, float(state.gate_hp) / float(world.balance.gate_health), accent)
	if p.facility == "greenhouse":
		GreenhouseView.beds(self, world, site)
	if p.facility == "garden":
		_garden(rect, site)
	if p.facility == "munitions" and state.claimed:
		draw_rect(Rect2(site + Vector2(65, 0), Vector2(80, 25)), Color("ab8860"))
		for i: int in range(6):
			draw_line(site + Vector2(75 + i * 10, 3), site + Vector2(75 + i * 10, 18), Color("dfb36e"), 4)
		_meter(site + Vector2(65, 33), 80, Firearms.progress(world) / float(world.catalog.firearm.craft_seconds), TEAL)
	if p.facility == "clinic" and state.looted:
		var bed := Rect2(site + Vector2(80, -16), Vector2(56, 32))
		draw_rect(bed.grow(3), INK)
		draw_rect(bed, Color("9dc1ce") if world.clinic.done else Color("626052"))
		draw_rect(Rect2(bed.position + Vector2(4, 4), Vector2(12, 24)), CREAM)
		if world.clinic.started and not world.clinic.done:
			_meter(site + Vector2(76, 28), 64, float(world.clinic.progress) / float(world.balance.clinic_seconds), TEAL)
		var batch: Dictionary = WorkOrders.current(world, "clinic_medicine")
		if WorkOrders.pending(batch):
			for x: int in range(3):
				draw_rect(Rect2(site + Vector2(82 + x * 18, -29), Vector2(8, 12)), Color("9dc1ce"))
			_meter(site + Vector2(76, 28), 64, float(batch.work_done) / float(batch.work_required), TEAL)
	if p.facility == "garage":
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
			var cut := Rect2()
			for area: Rect2 in Neighbourhood.openings(world):
				if area.intersects(Rect2(rect.position.x, y - 8, rect.size.x, 16)):
					cut = area
			if cut.has_area():
				draw_line(Vector2(rect.position.x, y), Vector2(cut.position.x, y), Color("968168"), 7)
				draw_line(Vector2(cut.end.x, y), Vector2(rect.end.x, y), Color("968168"), 7)
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



## Downed and hurt survivors get a pulsing ring; while carrying, every valid drop-off is ringed and the nearest has a guide line.
func _casualty_marks() -> void:
	var pulse: float = Access.pulse(Time.get_ticks_msec())
	for a: Dictionary in Carrying.casualties(world):
		if Carrying.carried(world, a.id) or not visible_world.grow(100).has_point(a.pos):
			continue
		var down: bool = float(a.hp) <= 0
		draw_arc(a.pos, 20 + 4 * pulse, 0, TAU, 28, RUST if down else CREAM, 2)
		_text(a.pos + Vector2(-24, -26), "DOWN" if down else "hurt", 13, RUST if down else CREAM)
	if not Carrying.occupied(world):
		return
	var havens: Array = Carrying.havens(world)
	for i: int in range(havens.size()):
		var site: Vector2 = Routes.point(havens[i].site)
		draw_arc(site, 46 + 5 * pulse, 0, TAU, 36, TEAL, 3)
		_text(site + Vector2(-40, -60), "Drop here · " + str(havens[i].name), 15, TEAL)
		if i == 0:
			var way: Vector2 = (site - world.player.pos)
			if way.length() > 80:
				var start: Vector2 = world.player.pos + way.normalized() * 40
				draw_dashed_line(start, start + way.normalized() * minf(way.length() - 80, 160), TEAL, 3, 10)


func _actor(a: Dictionary, zombie: bool) -> void:
	if a.id == "you" and Vehicle.driving(world):
		return
	var pos: Vector2 = a.pos
	var direction: Vector2 = a.facing
	if float(a.hp) <= 0:
		if Carrying.carried(world, a.id):
			return
		draw_line(pos - Vector2(12, 0), pos + Vector2(12, 0), Color("575e4d") if zombie else RUST, 9)
		return
	if zombie and a.has("runner"):
		_runner_tell(a)
	if zombie and a.get("kind") == "screecher":
		_screecher_tell(a)
	if zombie and a.get("kind") == "spitter":
		_spitter_tell(a)
	if zombie and ZombieTypes.kind(world.catalog, a).get("boss", false):
		_baboon(a)
		return
	var heavy: bool = a.get("kind") in ["brute", "breaker"]
	_ellipse(pos + Vector2(1, 4), Vector2(21, 9) if heavy else Vector2(15, 7), Color(0, 0, 0, 0.3))
	var body: Color = (Color("8a5a4a") if a.get("kind") == "brute" else Color("6f6a76") if a.get("kind") == "breaker" else Color("788357")) if zombie else (Color("dfad62") if a.id == "you" else (Color("7daeb9") if a.id == "mara" else (Color("91b69e") if a.id == "ellis" else Color("9dc1ce") if a.id == "june" else Color("e0903a") if a.id == "theo" else Color("8f6bc0") if a.id == "nia" else Color("4a6fb5") if a.id == "rowan" else Color("b7a0c8"))))
	if float(a.flash) > 0 and not Access.reduce_motion:
		body = Color("fff0d5")
	draw_line(pos + Vector2(-5, -3), pos + Vector2(-6, 3), INK, 5)
	draw_line(pos + Vector2(5, -3), pos + Vector2(6, 3), INK, 5)
	draw_rect(Rect2(pos + Vector2(-10, -22), Vector2(20, 20)), body)
	draw_rect(Rect2(pos + Vector2(-10, -10), Vector2(20, 4)), body.darkened(0.3))
	_head(pos + Vector2(0, -29), direction, zombie)
	if zombie and a.get("kind") == "screecher":
		draw_line(pos + Vector2(-10, -23), pos + Vector2(10, -23), RUST, 5)
		draw_line(pos + Vector2(7, -23), pos + Vector2(13, -8), RUST, 5)
		if a.screecher.phase == "inhale":
			draw_line(pos + Vector2(-13, -11), pos + Vector2(-8, -30), CREAM, 4)
			draw_line(pos + Vector2(13, -11), pos + Vector2(8, -30), CREAM, 4)
	if zombie and a.get("kind") == "spitter":
		draw_circle(pos + Vector2(0, -19), 7, Color("b8c95a"))
		draw_arc(pos + Vector2(0, -19), 7, 0, TAU, 12, INK, 2)
	if zombie and a.get("kind") == "runner":
		# Narrow shoulders and a forward diagonal sash identify it without colour.
		draw_line(pos + Vector2(-6, -22), pos + Vector2(6, -3), CREAM, 3)
		draw_line(pos + Vector2(-13, -16), pos + direction * 23 + Vector2(0, -20), Color("9caa73"), 4)
	if not zombie and a.id == "oliver":
		draw_rect(Rect2(pos + Vector2(-9, -40), Vector2(18, 9)), Color("698e50"))
		draw_line(pos + Vector2(-14, -31), pos + Vector2(14, -31), Color("9dceb3"), 3)
	if not zombie and Equipment.protected(world, a):
		_armour(pos, a.facing)
	if not zombie and Equipment.shielded(world, a):
		_shield(pos, a.facing)
	if not zombie and world.equipment.field_bag == a.id:
		var bag: Vector2 = pos + direction.orthogonal() * 15 + Vector2(0, -11)
		draw_line(bag + Vector2(-6, -7), bag + Vector2(6, -7), CREAM, 3)
		draw_rect(Rect2(bag - Vector2(9, 6), Vector2(18, 14)), INK)
		draw_rect(Rect2(bag - Vector2(7, 4), Vector2(14, 10)), Color("9dc1ce"))
	if not zombie and a.id != "ellis" and not Carrying.burdened(world, a.id) and not (a.id == "you" and float(world.shot.left) > 0):
		var grip: Vector2 = pos + Vector2(0, -14) + direction * 12
		var weapon: String = Equipment.weapon(world, a)
		draw_line(grip, grip + direction * (48 if weapon == "spear" else 36 if weapon == "sword" else 27), Color("c7b68e") if weapon == "bat" else Color("c1d1d0"), 5 if weapon != "sword" else 3)
		if weapon == "spear":
			var tip: Vector2 = grip + direction * 48
			draw_colored_polygon(PackedVector2Array([tip + direction * 9, tip - direction * 5 + direction.orthogonal() * 5, tip - direction * 5 - direction.orthogonal() * 5]), Color("c1d1d0"))
		if weapon == "crowbar":
			draw_line(grip + direction * 27, grip + direction * 27 + direction.orthogonal() * 10, Color("c1d1d0"), 4)
		draw_circle(grip, 3, Color("d7b08b"))
		if a.id != "you" and a.pos.distance_to(world.player.pos) < 170:
			_text(pos + Vector2(-16, -49), a.name, 13, CREAM)
	if not zombie and a.id not in ["you", "ellis"] and Carrying.burdened(world, a.id) and a.pos.distance_to(world.player.pos) < 170:
		_text(pos + Vector2(-16, -49), a.name, 13, CREAM)
	if a.id == "ellis" and a.pos.distance_to(world.player.pos) < 170:
		_text(pos + Vector2(-16, -49), "Ellis", 13, CREAM)
	if not zombie and Carrying.burdened(world, a.id):
		draw_line(pos + Vector2(-18, -25), pos + Vector2(14, -25), Color("9dc1ce"), 9)
		draw_circle(pos + Vector2(18, -25), 6, Color("d7b08b"))
	if a.id == "you" and float(world.shot.left) > 0:
		draw_line(pos + direction * 12, pos + direction * 32, INK, 7)
	if float(a.swing) > 0:
		var stats: Dictionary = Equipment.stats(world, a)
		var half_angle: float = acos(float(stats.cone))
		draw_arc(pos, float(stats.reach), direction.angle() - half_angle, direction.angle() + half_angle, 24, CREAM, 3)
	if float(a.hp) < (ZombieTypes.full_health(world.catalog, a) if zombie else 100.0):
		_meter(pos + Vector2(-15, 10), 30, float(a.hp) / (ZombieTypes.full_health(world.catalog, a) if zombie else 100.0), RUST)


## The way out: a wreck-and-barrier roadblock while the boss lives, an open gap with an arrow once it is down.
func _exit() -> void:
	if not Boss.configured(world.catalog):
		return
	var rect: Rect2 = Boss.exit_rect(world.catalog)
	if not rect.grow(40).intersects(visible_world):
		return
	if Boss.defeated(world):
		draw_rect(rect, Color(0.62, 0.81, 0.7, 0.18))
		draw_rect(rect, TEAL, false, 3)
		draw_line(rect.get_center() + Vector2(-26, 0), rect.get_center() + Vector2(26, 0), TEAL, 5)
		draw_line(rect.get_center() + Vector2(26, 0), rect.get_center() + Vector2(10, -12), TEAL, 5)
		draw_line(rect.get_center() + Vector2(26, 0), rect.get_center() + Vector2(10, 12), TEAL, 5)
		_text(rect.position + Vector2(8, -8), str(world.catalog.exit.name).to_upper() + " / EXIT", 15, TEAL)
		return
	draw_rect(rect, Color("3b2f2a"))
	for i: int in range(maxi(4, int(rect.size.x / 22.0) - 1)):
		var car := Rect2(rect.position + Vector2(6 + i * 22, 10 + (i % 2) * 22), Vector2(20, 34))
		draw_rect(car, Color("6d5a4d") if i % 2 == 0 else Color("55606a"))
		draw_rect(car.grow(-5), INK)
	draw_rect(rect, RUST, false, 3)
	_text(rect.position + Vector2(8, -8), str(world.catalog.exit.name).to_upper() + " / BLOCKED", 15, RUST)


## Where the player came in. It is always open, so it is drawn as a plain outlined gap.
func _entrance() -> void:
	if not world.catalog.has("entrance"):
		return
	var rect: Rect2 = Routes.rectangle(world.catalog.entrance.rect)
	if not rect.grow(40).intersects(visible_world):
		return
	draw_rect(rect, Color(0.84, 0.75, 0.56, 0.14))
	draw_rect(rect, CREAM, false, 3)
	_text(rect.position + Vector2(8, -8), str(world.catalog.entrance.name).to_upper() + " / ENTRANCE", 15, CREAM)


## Large, hunched and dark-furred, with a long muzzle toward its facing. Its health bar is always shown.
func _baboon(a: Dictionary) -> void:
	var pos: Vector2 = a.pos
	var direction: Vector2 = a.facing
	var fur: Color = Color("fff0d5") if float(a.flash) > 0 and not Access.reduce_motion else Color("5e4a3f")
	_ellipse(pos + Vector2(2, 6), Vector2(34, 14), Color(0, 0, 0, 0.35))
	draw_line(pos + Vector2(-18, -4), pos + Vector2(-20, 8), INK, 9)
	draw_line(pos + Vector2(18, -4), pos + Vector2(20, 8), INK, 9)
	draw_rect(Rect2(pos + Vector2(-24, -38), Vector2(48, 36)), fur)
	draw_rect(Rect2(pos + Vector2(-24, -22), Vector2(48, 6)), fur.darkened(0.3))
	draw_line(pos + Vector2(-24, -34), pos + Vector2(-34, -10), fur, 9)
	draw_line(pos + Vector2(24, -34), pos + Vector2(34, -10), fur, 9)
	var head: Vector2 = pos + Vector2(0, -46)
	draw_circle(head, 14, fur.lightened(0.1))
	draw_line(head, head + direction * 20, Color("a07a62"), 10)
	draw_circle(head + direction.orthogonal() * 6 + direction * 6, 2.5, CREAM)
	draw_circle(head - direction.orthogonal() * 6 + direction * 6, 2.5, CREAM)
	_text(pos + Vector2(-26, -74), str(ZombieTypes.kind(world.catalog, a).name).to_upper(), 14, CREAM)
	_meter(pos + Vector2(-32, 14), 64, float(a.hp) / ZombieTypes.full_health(world.catalog, a), RUST)


func _runner_tell(a: Dictionary) -> void:
	var state: Dictionary = a.runner
	if state.phase not in ["tell", "dash", "recover"]:
		return
	if state.phase == "recover":
		draw_arc(a.pos, 20, 0, TAU, 24, CREAM, 2)
		return
	var direction := Vector2(float(state.dx), float(state.dy))
	var config: Dictionary = ZombieTypes.kind(world.catalog, a)
	var length: float = float(config.lunge_distance) if state.phase == "tell" else float(state.distance)
	var end: Vector2 = a.pos + direction * length
	for side: float in [-1.0, 1.0]:
		var offset: Vector2 = direction.orthogonal() * 15 * side
		draw_line(a.pos + offset, end + offset, INK, 5)
		draw_line(a.pos + offset, end + offset, CREAM, 2)
		draw_line(end, end - direction * 13 + offset, CREAM, 3)
	if state.phase == "tell":
		_text(a.pos + Vector2(-25, -57), "LUNGE", 13, CREAM)
		_meter(a.pos + Vector2(-22, -50), 44, 1.0 - float(state.left) / float(config.lunge_tell), CREAM)


func _screecher_tell(a: Dictionary) -> void:
	var state: Dictionary = a.screecher
	var config: Dictionary = world.catalog.zombies.types.screecher
	if state.phase == "inhale":
		var progress: float = 1.0 - float(state.left) / float(config.call_tell)
		draw_arc(a.pos, 23, -PI / 2, -PI / 2 + TAU * progress, 32, CREAM, 3)
		for side: int in [-1, 1]:
			draw_line(a.pos + Vector2(side * 33, -32), a.pos + Vector2(side * 23, -24), CREAM, 2)
		_text(a.pos + Vector2(-27, -57), "INHALE", 13, CREAM)
	if float(state.pulse) > 0:
		var progress: float = 1.0 - float(state.pulse) / float(config.call_pulse)
		var radius: float = float(world.catalog.attention.events.screecher.radius)
		for i: int in range(2):
			var reach: float = 25 + maxf(0.0, progress - i * 0.15) * radius
			draw_arc(a.pos, reach, 0, TAU, 64, CREAM, 2)
		_text(a.pos + Vector2(-21, -57), "CALL", 13, CREAM)


func _spitter_tell(a: Dictionary) -> void:
	var state: Dictionary = a.spitter
	if state.phase != "aim":
		return
	var config: Dictionary = world.catalog.zombies.types.spitter
	var point := Vector2(float(state.tx), float(state.ty))
	var progress: float = 1.0 - float(state.left) / float(config.spit_tell)
	draw_arc(point, float(config.pool_radius), 0, TAU, 32, CREAM, 2)
	draw_arc(point, float(config.pool_radius) * progress, 0, TAU, 32, CREAM, 3)
	draw_line(point + Vector2(-8, 0), point + Vector2(8, 0), CREAM, 2)
	draw_line(point + Vector2(0, -8), point + Vector2(0, 8), CREAM, 2)
	_text(a.pos + Vector2(-20, -57), "AIM", 13, CREAM)


func _vehicle() -> void:
	if not bool(world.vehicle.present):
		return
	var config: Dictionary = world.catalog.vehicle
	var length: float = float(config.half_length)
	var width: float = float(config.half_width)
	var wrecked: bool = float(world.vehicle.hull) <= 0
	draw_set_transform(Vehicle.pos(world), float(world.vehicle.heading), Vector2.ONE)
	draw_rect(Rect2(-length, -width, length * 2, width * 2), Color("4a4f52") if wrecked else Color("4f7a9a"))
	draw_rect(Rect2(-length * 0.55, -width + 2, length * 0.9, width * 2 - 4), Color("6b6f6f") if wrecked else CREAM)
	draw_rect(Rect2(length * 0.4, -width + 3, length * 0.45, width * 2 - 6), INK)
	draw_rect(Rect2(-length, -width, length * 2, width * 2), INK, false, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if Vehicle.near(world) or Vehicle.driving(world):
		var hull: float = float(world.vehicle.hull) / float(config.hull)
		_meter(Vehicle.pos(world) + Vector2(-22, -width - 14), 44, hull, CREAM)


## An untouched cache is a small pile of crates with a ring; a searched one is just empty crates.
func _caches() -> void:
	for c: Dictionary in world.catalog.get("caches", []):
		var at: Vector2 = Routes.point(c.pos)
		if not Rect2(at - Vector2(60, 60), Vector2(120, 120)).intersects(visible_world):
			continue
		var taken: bool = world.caches_taken.has(c.id)
		for offset: Vector2 in [Vector2(-14, 2), Vector2(6, -6), Vector2(10, 10)]:
			draw_rect(Rect2(at + offset - Vector2(9, 8), Vector2(18, 16)), Color("6b5a47") if taken else Color("a98a5f"))
			draw_rect(Rect2(at + offset - Vector2(9, 8), Vector2(18, 16)), INK, false, 2.0)
		if not taken:
			draw_arc(at, 34, 0, TAU, 24, CREAM, 2.0)
			_text(at + Vector2(-34, -44), str(c.name).to_upper(), 13, CREAM)


func _spits() -> void:
	var config: Dictionary = world.catalog.zombies.types.spitter
	for s: Dictionary in world.spits:
		var at := Vector2(float(s.x), float(s.y))
		if s.t == "glob":
			draw_circle(at, 6, Color("b8c95a"))
			draw_arc(at, 6, 0, TAU, 12, INK, 2)
		else:
			var radius: float = float(config.pool_radius)
			draw_circle(at, radius, Color(0.55, 0.65, 0.2, 0.35))
			# Dashed edge keeps the hazard readable without colour.
			for i: int in range(0, 16, 2):
				draw_arc(at, radius, i * TAU / 16, (i + 1) * TAU / 16, 4, CREAM, 2)


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
	if Facility.state(world, "garage").claimed and world.equipment.iron.is_empty():
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
