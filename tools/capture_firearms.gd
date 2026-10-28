extends "res://addons/hatchery/testing/capture_runner.gd"
const Checks = preload("res://tools/checks/checks_firearms.gd")
const Tasks = preload("res://scripts/sim/tasks.gd")


func tour() -> void:
	var game: Node = await open_scene("res://scenes/town.tscn")
	game.save_state.store.enabled = false
	game.world = Checks.prepared()
	game.view.world = game.world
	game.set_process(false)
	game.world.player.pos = Vector2(1800, 350)
	var ellis: Dictionary = Tasks.person(game.world, "ellis")
	ellis.pos = Vector2(1840, 370)
	game.camera.position = Vector2(1520, 360)
	game.camera.force_update_scroll()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(4)
	await shot("east_house_rescue")
	# Exercise right-click input through the real process handler at the new map edge.
	game.world.player.pos = Vector2(1650, 580)
	var z: Dictionary = game.world.zombies[0]
	z.hp = 100.0
	z.pos = Vector2(1950, 580)
	game.camera.position = Vector2(1520, 580)
	game.camera.force_update_scroll()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.position = game.get_viewport().get_canvas_transform() * z.pos
	click.pressed = true
	Input.warp_mouse(click.position)
	Input.parse_input_event(click)
	await frames(2)
	game.paused = false
	game._process(0.0)
	click.pressed = false
	Input.parse_input_event(click)
	if int(game.world.firearms.bullets) != 5 or float(z.hp) != 10:
		push_error("Right click failed: bullets=%s hp=%s aim=%s cursor=%s" % [game.world.firearms.bullets, z.hp, game.world.aim, game.get_global_mouse_position()])
		quit(1)
		return
	await frames(3)
	await shot("pistol_shot")
	z.hp = 0.0
	game.world.player.pos = Vector2(1800, 800)
	ellis.pos = Vector2(1840, 800)
	game.assign_survivor("ellis", "ammo")
	game.world.survivors[0].pos = Vector2(1800, 580)
	game.world.step(0.05)
	game.world.firearms.progress = 7.5
	game.world.shot.left = 0.0
	game.camera.position = Vector2(1520, 800)
	game.camera.force_update_scroll()
	game.hud.refresh(game.world, false)
	game.view.queue_redraw()
	await frames(3)
	await shot("bullet_workshop")
	game.paused = true
	game.hud.refresh(game.world, true)
	game.hud.show_menu()
	# Exercise actual assignment selector and verify Ellis's disabled guard choices.
	var picker: OptionButton = game.hud.team_orders.rows.ellis.picker
	for i: int in range(picker.item_count):
		var task: String = picker.get_item_metadata(i)
		if task in ["home", "engage"] and not picker.is_item_disabled(i):
			push_error("Ellis guard/combat choice is enabled.")
			quit(1)
			return
		if task == "ammo":
			picker.item_selected.emit(i)
	game.hud.menu.get_child(0).scroll_vertical = 200
	await frames(4)
	await shot("bullet_orders")
