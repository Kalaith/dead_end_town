extends "res://addons/hatchery/testing/capture_runner.gd"
## Default in-engine capture tour: no OS input, no focus changes. Input is fed
## to the game as engine events and frames are read from the viewport.
## Run through tools/Capture.ps1, which opens the window off-screen.


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	await shot("street_start")
	town.command("resume")
	await hold("move_right", 1.0)
	await shot("street_walk")


## Holds an input action for `duration` seconds as a real engine input event.
func hold(action: String, duration: float) -> void:
	Input.action_press(action)
	await seconds(duration)
	Input.action_release(action)
	await frames(5)
