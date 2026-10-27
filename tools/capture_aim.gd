extends "res://addons/hatchery/testing/capture_runner.gd"


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	for z: Dictionary in game.world.zombies:
		z.hp = 0.0
	game.command("resume")
	var keys: Array[int] = [KEY_W, KEY_S, KEY_A, KEY_D]
	var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var labels: Array[String] = ["attack_up", "attack_down", "attack_left", "attack_right"]
	for i: int in range(keys.size()):
		game.world.player.pos = Vector2(500, 580)
		game.camera.position = Vector2(640, 540)
		# Actual game input: move the pointer away, then use keyboard-only combat.
		var pointer := InputEventMouseMotion.new()
		pointer.position = Vector2(1150, 400)
		pointer.relative = Vector2(20, 0)
		Input.parse_input_event(pointer)
		_key(keys[i], true)
		_key(KEY_SPACE, true)
		await frames(2)
		if game.world.player.facing != directions[i] or float(game.world.player.swing) <= 0:
			push_error("Keyboard attack capture did not face " + labels[i])
			quit(1)
			return
		await shot(labels[i])
		_key(KEY_SPACE, false)
		_key(keys[i], false)
		await seconds(0.6)


func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
