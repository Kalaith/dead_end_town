extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")


func check_raider_settles_in_a_building_that_needs_zombies_then_wanders() -> String:
	var w: RefCounted = _quiet()
	w.balance.settle_percent = 100
	w.player.hp = 0.0
	var z: Dictionary = _raider(w, Vector2(1410, 580))
	for i: int in range(2400):
		w.step(0.05)
	var inside: bool = false
	for p: Dictionary in w.catalog.properties:
		inside = inside or Rect2(p.rect[0], p.rect[1], p.rect[2], p.rect[3]).has_point(z.pos)
	if not inside or float(z.hp) <= 0:
		return "Raider never reached a building needing zombies."
	return ""


func check_raider_leaves_by_the_road_when_no_building_needs_zombies() -> String:
	var w: RefCounted = _quiet()
	for p: Dictionary in w.catalog.properties:
		p.hidden_zombies = 0
	w.player.hp = 0.0
	var z: Dictionary = _raider(w, Vector2(1410, 580))
	for i: int in range(6000):
		w.step(0.05)
		if not w.zombies.has(z):
			return ""
	return "Raider with nowhere to stay never left the map."


func check_defeated_raider_keeps_its_corpse() -> String:
	var w: RefCounted = _quiet()
	var z: Dictionary = _raider(w, Vector2(700, 580))
	z.hp = 0.0
	w.step(0.05)
	return "" if w.zombies.has(z) else "Sweep removed a defeated raider."


func _raider(w: RefCounted, pos: Vector2) -> Dictionary:
	var z: Dictionary = World.actor("wave0_east_0", "Shambler", pos, 60.0)
	z.home = "street"
	z.raid = true
	w.zombies.append(z)
	return z


func _quiet() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for a: Dictionary in w.survivors:
		a.hp = 0.0
	w.pressure.next = 1.0e9
	return w
