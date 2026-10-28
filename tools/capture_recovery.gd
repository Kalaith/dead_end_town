extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_recovery.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")


func key(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.keycode = KEY_E
	event.pressed = pressed
	Input.parse_input_event(event)


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.set_process(false)
	game.world = Checks.quiet()
	game.world.properties.home.open = true
	game.world.rebuild_routes()
	game.world.player.pos = Vector2(1080, 400)
	game.world.survivors[0].pos = Vector2(1100, 400)
	game.world.survivors[0].hp = 0.0
	game.view.world = game.world
	game.camera.position = Vector2(1080, 400)
	game.camera.force_update_scroll()
	game.command("resume")
	key(true)
	await frames(2)
	for i: int in range(20):
		game._process(0.05)
	if game.world.carry.progress < 0.9 or Carrying.occupied(game.world):
		push_error("Held E did not begin a timed casualty lift")
		quit(1)
		return
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	await frames(3)
	await shot("casualty_lift")
	for i: int in range(21):
		game._process(0.05)
	key(false)
	await frames(2)
	if game.world.carry.patient != "mara":
		push_error("Held E did not lift Mara through the real input path")
		quit(1)
		return
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	await frames(3)
	await shot("casualty_carried")
	for i: int in range(650):
		var target := Vector2(360, 350)
		if game.world.player.pos.distance_to(target) < 12:
			break
		var next: Vector2 = game.world.routes.waypoint(game.world.player.pos, target)
		game.world.move_input = game.world.player.pos.direction_to(next)
		game.world.step(0.05)
	game.world.move_input = Vector2.ZERO
	var food: int = game.world.food
	key(true)
	await frames(2)
	key(false)
	await frames(2)
	if Carrying.occupied(game.world) or game.world.survivors[0].hp != 0 or game.world.food != food:
		push_error("Shelter drop failed or silently started paid rest")
		quit(1)
		return
	key(true)
	await frames(2)
	key(false)
	await frames(2)
	if game.world.food != food - 2 or game.world.survivors[0].hp != 0:
		push_error("Short E failed to pay for timed local recovery")
		quit(1)
		return
	for i: int in range(150):
		game._process(0.05)
	game.camera.position = Vector2(640, 365)
	game.camera.force_update_scroll()
	game.world.messages.clear()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("home_rest")
	game.command("menu")
	var before: Dictionary = game.save_state.snapshot(game.world)
	game._process(0.2)
	if game.save_state.snapshot(game.world) != before:
		push_error("Pause advanced casualty recovery")
		quit(1)
		return
	game.command("resume")
	for i: int in range(151):
		game._process(0.05)
	if game.world.survivors[0].hp != 50 or not game.world.home_rest.patients.is_empty():
		push_error("Local timed rest failed to revive to fifty health")
		quit(1)
		return
