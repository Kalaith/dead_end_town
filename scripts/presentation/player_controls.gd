extends RefCounted
## Explicit input intent prevents an idle cursor from steering keyboard combat.
var mouse_aiming: bool = false


func observe(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not event.relative.is_zero_approx():
		mouse_aiming = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		mouse_aiming = true
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE]:
		mouse_aiming = false


func direction(movement: Vector2, cursor_offset: Vector2, previous: Vector2, mouse_attack: bool, keyboard_attack: bool) -> Vector2:
	if mouse_attack:
		mouse_aiming = true
	elif keyboard_attack:
		mouse_aiming = false
	if mouse_aiming:
		return cursor_offset.normalized() if not cursor_offset.is_zero_approx() else previous
	return movement.normalized() if not movement.is_zero_approx() else previous
