extends SceneTree
## Settings: defaults include every rebindable action, a rebind moves the action's key, volumes reach their buses,
## the interface size multiplies the window's scale and the HUD's own preferences share the store. Run:
## Godot --headless --path . --script res://tools/checks/check_settings.gd
const GameSettings = preload("res://scripts/presentation/game_settings.gd")
const Access = preload("res://scripts/presentation/access.gd")
var failures: int = 0


func _init() -> void:
	var prefs := GameSettings.new(self)
	prefs.store.save_enabled = false
	prefs.apply_all()
	_expect("every rebindable action starts with its project key", prefs.store.key_bindings.size() == GameSettings.ACTIONS.size())
	_expect("rebinding the team key to K works", prefs.store.rebind("team", 0, KEY_K).is_empty() and InputMap.action_get_events("team").any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_K))
	_expect("a key already used elsewhere is refused", not prefs.store.rebind("team", 0, KEY_E).is_empty())
	prefs.store.set_value("effects", 0.0)
	prefs.apply("effects")
	_expect("silencing effects lowers its bus", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Effects")) <= -79.0)
	prefs.store.set_value("ui_scale", 1.0)
	prefs.apply("ui_scale")
	_expect("the largest interface size scales the window by 1.6", is_equal_approx(root.content_scale_factor, 1.6))
	_expect("slot 3 and its name are preferences too", prefs.store.set_value("slot", 3) and prefs.store.set_value("slot_name_3", "Late game"))
	var before: Color = Access.threat()
	for key: String in ["colour_safe", "captions", "reduce_motion"]:
		prefs.store.set_value(key, true)
	prefs.apply("colour_safe")
	_expect("colour-safe changes the threat colour", Access.colour_safe and Access.threat() != before)
	_expect("reduced motion holds the pulse still", Access.pulse(1234) == 1.0 and Access.captions)
	prefs.release()
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
