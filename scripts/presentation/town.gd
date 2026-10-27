extends Node2D
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const View = preload("res://scripts/presentation/town_view.gd")
const Hud = preload("res://scripts/presentation/hud.gd")
var world: RefCounted
var save_state: RefCounted
var view: Node2D
var camera: Camera2D
var hud: Control
var paused: bool = true
var accumulator: float = 0.0
var storage_enabled: bool = true


func _ready() -> void:
	var data: Dictionary = Catalog.read()
	if data.is_empty():
		get_tree().quit(1)
		return
	world = World.new(data)
	save_state = SaveState.new(data)
	storage_enabled = not OS.get_cmdline_user_args().has("--no-save")
	save_state.store.enabled = storage_enabled
	view = View.new()
	view.world = world
	add_child(view)
	camera = Camera2D.new()
	camera.position = Vector2(640, 365)
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	canvas.add_child(hud)
	hud.requested.connect(command)
	hud.show_menu(true)
	hud.refresh(world, paused)
	# Loading is explicit, so opening the prototype cannot overwrite a run.
	if storage_enabled:
		save_state.store.load_data()
		if not save_state.store.last_error.is_empty():
			hud.menu_status.text = save_state.store.last_error


func _process(dt: float) -> void:
	if world == null:
		return
	if not paused:
		world.move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		world.aim = world.player.pos.direction_to(get_global_mouse_position())
		world.working = Input.is_action_pressed("work")
		accumulator += minf(dt, 0.2)
		var step: float = float(world.balance.step)
		while accumulator >= step:
			world.step(step)
			accumulator -= step
		if Input.is_action_pressed("attack"):
			world.attack()
	var target := Vector2(clampf(world.player.pos.x, 640, 800), clampf(world.player.pos.y - 40, 360, 800))
	camera.position = camera.position.lerp(target, 1.0 - exp(-dt * 8))
	view.queue_redraw()
	hud.refresh(world, paused, dt)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_TAB]:
			command("menu")
			get_viewport().set_input_as_handled()
			return
		if not paused:
			match event.physical_keycode:
				KEY_1:
					world.order("Follow")
				KEY_2:
					world.order("Hold")
				KEY_3:
					world.order("Engage")
				KEY_4:
					world.order("Home")
				KEY_G:
					world.post_road_guard()
				KEY_F:
					world.assign_mara()
	if not paused and event.is_action_pressed("interact"):
		world.interact()


func command(value: String) -> void:
	match value:
		"menu":
			paused = not paused
			if paused:
				hud.show_menu()
		"resume":
			paused = false
		"save":
			var okay: bool = save_state.store.save_data(save_state.snapshot(world))
			hud.menu_status.text = "Street saved. Previous good save retained as backup." if okay else save_state.store.last_error
		"load":
			var data: Dictionary = save_state.store.load_data()
			if data.is_empty():
				hud.menu_status.text = "No saved street yet." if save_state.store.last_error.is_empty() else save_state.store.last_error
			else:
				world = save_state.restore(data)
				view.world = world
				accumulator = 0
				hud.menu_status.text = "Street restored. Resume when ready."
		"new":
			if not save_state.store.keep_previous():
				hud.menu_status.text = save_state.store.last_error
				return
			world = World.new(world.catalog)
			view.world = world
			accumulator = 0
			hud.menu_status.text = "New street ready. Your saved street is preserved until you save."
