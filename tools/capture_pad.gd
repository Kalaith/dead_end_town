extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour driven only by gamepad events: Start pauses, the d-pad moves focus through the pause menu and A
## presses, Back opens the work board, and the settings page lists the gamepad buttons.
## Run through tools/Capture.ps1 -Tour res://tools/capture_pad.gd.


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	town.command("resume")
	await seconds(0.3)
	await press(JOY_BUTTON_START)
	await shot("pad_pause")
	for button: int in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_A]:
		await press(button)
	await seconds(0.2)
	print("pad: focus on %s, section %s" % [str(town.get_viewport().gui_get_focus_owner()), town.hud.section])
	await shot("pad_tab_pressed")
	await press(JOY_BUTTON_START)
	await seconds(0.2)
	print("pad: paused after second Start = %s" % town.paused)
	town.command("menu")
	town.hud.show_section("Help")
	town.hud.open_settings()
	town.hud.settings_host.page.tabs.current_tab = 1
	await seconds(0.3)
	var scroll: Node = town.hud.settings_host.page.tabs.get_child(1)
	if scroll is ScrollContainer:
		scroll.scroll_vertical = 100000
	await seconds(0.3)
	await shot("pad_bindings")


## A press and release of `button` as real engine input events.
func press(button: int) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		event.device = 0
		Input.parse_input_event(event)
		await frames(3)
