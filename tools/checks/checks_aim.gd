extends RefCounted
const Controls = preload("res://scripts/presentation/player_controls.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")


func check_keyboard_swings_follow_movement_and_keep_last_facing_when_stopped() -> String:
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var controls := Controls.new()
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(10, 0)
		controls.observe(motion)
		var aim: Vector2 = controls.direction(direction, -direction * 300, Vector2.DOWN, false, true)
		if aim != direction:
			return "Space followed the idle cursor instead of keyboard movement."
		aim = controls.direction(Vector2.ZERO, -direction * 300, aim, false, true)
		if aim != direction:
			return "Stopping while holding Space lost the last movement direction."
	return ""


func check_mouse_aim_and_keyboard_intent_switch_without_a_cursor_snap() -> String:
	var controls := Controls.new()
	var aim: Vector2 = controls.direction(Vector2.UP, Vector2.LEFT * 200, Vector2.DOWN, true, false)
	if aim != Vector2.LEFT:
		return "Mouse click did not aim while moving."
	var key := InputEventKey.new()
	key.physical_keycode = KEY_UP
	key.pressed = true
	controls.observe(key)
	aim = controls.direction(Vector2.UP, Vector2.LEFT * 200, aim, false, false)
	if aim != Vector2.UP:
		return "Arrow movement did not return control of facing to the keyboard."
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(2, 0)
	controls.observe(motion)
	aim = controls.direction(Vector2.ZERO, Vector2.RIGHT * 200, aim, false, false)
	if aim != Vector2.RIGHT:
		return "Explicit mouse movement failed to aim."
	aim = controls.direction(Vector2.ZERO, Vector2.ZERO, aim, true, false)
	return "Cursor over the player erased facing" if aim != Vector2.RIGHT else ""


func check_keyboard_aim_hits_only_the_facing_target_and_swing_stays_locked() -> String:
	var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for direction: Vector2 in directions:
		var w := World.new(Catalog.read())
		w.player.pos = Vector2(500, 580)
		for z: Dictionary in w.zombies:
			z.hp = 0.0
		for i: int in range(4):
			w.zombies[i].pos = w.player.pos + directions[i] * 60
			w.zombies[i].hp = 60.0
		var controls := Controls.new()
		w.aim = controls.direction(direction, -direction * 200, w.aim, false, true)
		w.face_aim()
		w.attack()
		for i: int in range(4):
			var expected: float = 30.0 if directions[i] == direction else 60.0
			if float(w.zombies[i].hp) != expected:
				return "Keyboard swing hit outside its facing direction."
		w.aim = -direction
		w.face_aim()
		w.step(0.05)
		if w.player.facing != direction:
			return "Turning redirected a swing after its damage was resolved."
		var save := SaveState.new(w.catalog)
		var restored: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
		if restored == null or restored.aim != direction or restored.player.facing != direction:
			return "Reload did not retain the visible facing direction."
	return ""
