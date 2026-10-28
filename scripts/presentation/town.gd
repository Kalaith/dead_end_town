extends Node2D
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const ConstructionMenu = preload("res://scripts/presentation/construction_menu.gd")
const Production = preload("res://scripts/sim/production.gd")
const SliceObjective = preload("res://scripts/sim/slice_objective.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const View = preload("res://scripts/presentation/town_view.gd")
const Hud = preload("res://scripts/presentation/hud.gd")
const PlayerControls = preload("res://scripts/presentation/player_controls.gd")
var world: RefCounted
var save_state: RefCounted
var view: Node2D
var camera: Camera2D
var hud: Control
var paused: bool = true
var accumulator: float = 0.0
var completion_shown: bool = false
var storage_enabled: bool = true
var controls := PlayerControls.new()


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
	hud.production_requested.connect(configure_production)
	hud.production_cancelled.connect(cancel_production)
	hud.work_cancelled.connect(cancel_work)
	hud.assignment_requested.connect(assign_survivor)
	hud.equipment_requested.connect(equip)
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
		world.working = Input.is_action_pressed("work")
		accumulator += minf(dt, 0.2)
		var step: float = float(world.balance.step)
		while accumulator >= step:
			world.step(step)
			accumulator -= step
	var target := Vector2(clampf(world.player.pos.x, 640, float(world.catalog.bounds[0]) - 640), clampf(world.player.pos.y - 40, 360, 800))
	camera.position = camera.position.lerp(target, 1.0 - exp(-dt * 8))
	if not paused:
		# Use the current camera transform and actor position, including on frames
		# shorter than one fixed step, before accepting an attack.
		camera.force_update_scroll()
		world.aim = controls.direction(world.move_input, get_global_mouse_position() - world.player.pos, world.aim, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT), Input.is_physical_key_pressed(KEY_SPACE))
		world.face_aim()
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			world.shoot()
		elif Input.is_action_pressed("attack"):
			world.attack()
	if world.slice_state.phase == "complete" and not completion_shown:
		completion_shown = true
		paused = true
		hud.show_menu()
		hud.pause_title.text = "A STREET WORTH KEEPING / SLICE COMPLETE"
		hud.first_button.text = "Continue the street"
	view.queue_redraw()
	hud.refresh(world, paused, dt)


func _unhandled_input(event: InputEvent) -> void:
	if not paused:
		controls.observe(event)
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
				KEY_Q:
					world.salvage()
				KEY_G:
					world.post_road_guard()
				KEY_F:
					command("team")
				KEY_J:
					command("work")
	if not paused and event.is_action_pressed("interact"):
		world.interact()


func command(value: String) -> void:
	match value:
		"watch":
			SliceObjective.start(world)
			hud.menu_status.text = world.messages.back()
			hud.refresh(world, paused)
		"work":
			if world.properties.munitions.looted or ConstructionMenu.available(world):
				paused = true
				hud.refresh(world, true)
				hud.show_menu()
				hud.show_section("Work")
		"team":
			paused = true
			hud.refresh(world, paused)
			hud.show_menu()
			hud.show_section("Team")
			hud.team_orders.focus_orders()
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
				completion_shown = false
				controls = PlayerControls.new()
				view.world = world
				accumulator = 0
				hud.menu_status.text = "Street restored. Resume when ready."
		"new":
			if not save_state.store.keep_previous():
				hud.menu_status.text = save_state.store.last_error
				return
			completion_shown = false
			world = World.new(world.catalog)
			controls = PlayerControls.new()
			view.world = world
			accumulator = 0
			hud.menu_status.text = "New street ready. Your saved street is preserved until you save."


func assign_survivor(id: String, task: String) -> void:
	world.assign_survivor(id, task)
	hud.menu_status.text = world.messages.back()
	hud.refresh(world, paused)


func equip(id: String, slot: String, item: String) -> void:
	Equipment.equip(world, id, slot, item)
	hud.menu_status.text = world.messages.back()
	hud.refresh(world, paused)


func configure_production(mode: String, target: int, reserve: int) -> void:
	if Production.configure(world, mode, target, reserve):
		hud.menu_status.text = ""
		hud.refresh(world, paused)


func cancel_production() -> void:
	if Production.cancel(world):
		hud.menu_status.text = "Batch cancelled"
		hud.refresh(world, paused)


func cancel_work(socket: String) -> void:
	if Neighbourhood.cancel(world, socket) or Restoration.cancel(world, socket) or Roadworks.cancel(world, socket):
		hud.menu_status.text = "Work cancelled"
		hud.refresh(world, paused)
