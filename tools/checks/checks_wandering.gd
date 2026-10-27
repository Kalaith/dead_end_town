extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Territory = preload("res://scripts/sim/territory.gd")


func check_bat_hits_only_nearest_valid_zombie_independent_of_array_order() -> String:
	var w: RefCounted = _quiet()
	w.player.pos = Vector2(500, 580)
	w.aim = Vector2.RIGHT
	for entry: Array in [[0, Vector2(565, 580)], [1, Vector2(540, 580)], [2, Vector2(450, 580)], [3, Vector2(585, 580)]]:
		w.zombies[entry[0]].pos = entry[1]
		w.zombies[entry[0]].hp = 60.0
	w.attack()
	for i: int in range(4):
		if float(w.zombies[i].hp) != (30.0 if i == 1 else 60.0):
			return "Bat hit multiple zombies, a farther zombie, behind itself or beyond reach."
	w.attack()
	if float(w.zombies[1].hp) != 30.0:
		return "Attack cooldown allowed another hit."
	w.player.cooldown = 0.0
	w.attack()
	if float(w.zombies[1].hp) != 0.0 or float(w.zombies[0].hp) != 60.0:
		return "Second swing did not independently hit just one target."
	return ""


func check_bat_cannot_hit_through_a_property_wall() -> String:
	var w: RefCounted = _quiet()
	w.player.pos = Vector2(770, 390)
	w.aim = Vector2.RIGHT
	w.zombies[0].pos = Vector2(825, 390)
	w.zombies[0].hp = 60.0
	w.attack()
	return "Bat hit through property fence" if float(w.zombies[0].hp) != 60.0 else ""


func check_residents_keep_wandering_after_their_property_falls() -> String:
	var w: RefCounted = _quiet()
	w.claim("garden")
	var z: Dictionary = w.zombies[0]
	z.hp = 60.0
	z.pos = Vector2(1080, 390)
	Territory.step(w, 8)
	if w.properties.garden.claimed:
		return "Occupation fixture did not fall."
	var start: Vector2 = z.pos
	var headings: Dictionary = {}
	var furthest: float = 0.0
	for i: int in range(400):
		w.step(0.05)
		headings[z.roam_angle] = true
		furthest = maxf(furthest, start.distance_to(z.pos))
		if not w.routes.walkable(z.pos):
			return "Wanderer crossed a solid fence or building."
	if headings.size() < 5 or furthest < 40:
		return "Occupier froze at a porch or failed to change directions."
	return ""


func check_moving_people_do_not_redirect_wandering_zombies() -> String:
	var a: RefCounted = _quiet()
	var b: RefCounted = _quiet()
	for w: RefCounted in [a, b]:
		w.zombies[0].hp = 60.0
		w.zombies[0].pos = Vector2(500, 580)
	for i: int in range(200):
		# Visible and within old awareness, but outside contact range.
		b.player.pos = b.zombies[0].pos + Vector2(-100, 0)
		a.step(0.05)
		b.step(0.05)
		if a.zombies[0].pos != b.zombies[0].pos or a.zombies[0].roam_angle != b.zombies[0].roam_angle:
			return "Zombie redirected toward a nearby person."
	return ""


func check_mid_wander_json_reload_preserves_random_sequence() -> String:
	var w := World.new(Catalog.read())
	for i: int in range(73):
		w.step(0.05)
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.roam_rng.state != w.roam_rng.state:
		return "Mid-wander save lost random generator precision."
	for i: int in range(400):
		w.step(0.05)
		loaded.step(0.05)
	if not _same(save.snapshot(w), save.snapshot(loaded)):
		return "Wandering changed after JSON reload."
	return ""


func check_schema_six_migration_and_invalid_wandering_state() -> String:
	var w := World.new(Catalog.read())
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 6
	old.erase("roam_rng_state")
	for a: Dictionary in [old.player] + old.survivors + old.zombies:
		a.erase("roam_angle")
		a.erase("roam_left")
	var loaded: RefCounted = save.restore(old)
	if loaded == null or loaded.materials != w.materials or loaded.properties != w.properties:
		return "Schema-six migration changed progress."
	for value: Variant in ["bad", "9223372036854775808", 123]:
		var raw: Dictionary = save.snapshot(w)
		raw.roam_rng_state = value
		if save.valid(raw):
			return "Malformed RNG state accepted."
	for value: Variant in [-1, "bad", 100]:
		var raw: Dictionary = save.snapshot(w)
		raw.zombies[0].roam_left = value
		if save.valid(raw):
			return "Malformed wandering clock accepted."
	var data: Dictionary = Catalog.read()
	data.balance.roam_turn_min = 10
	return "Reversed turn interval accepted" if Catalog.problems(data).is_empty() else ""


func _quiet() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for a: Dictionary in w.survivors:
		a.hp = 0.0
	return w


func _same(a: Variant, b: Variant) -> bool:
	# JSON rounds double-precision clocks; positions and RNG state must still agree.
	if a is float or a is int:
		return (b is float or b is int) and absf(float(a) - float(b)) < 0.0000001
	if a is Dictionary:
		if not b is Dictionary or a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not _same(a[key], b[key]):
				return false
		return true
	if a is Array:
		if not b is Array or a.size() != b.size():
			return false
		for i: int in range(a.size()):
			if not _same(a[i], b[i]):
				return false
		return true
	return a == b
