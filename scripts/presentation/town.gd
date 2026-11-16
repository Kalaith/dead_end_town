extends Node2D
const Medicine = preload("res://scripts/sim/medicine.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Defeat = preload("res://scripts/sim/defeat.gd")
const Greenhouse = preload("res://scripts/sim/greenhouse.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")
const Roster = preload("res://scripts/sim/roster.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Repairs = preload("res://scripts/sim/repairs.gd")
const Roadworks = preload("res://scripts/sim/roadworks.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")
const Neighbourhood = preload("res://scripts/sim/neighbourhood.gd")
const ConstructionMenu = preload("res://scripts/presentation/construction_menu.gd")
const Production = preload("res://scripts/sim/production.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const AreaTravel = preload("res://scripts/core/area_travel.gd")
const SaveSlots = preload("res://scripts/core/save_slots.gd")
const View = preload("res://scripts/presentation/town_view.gd")
const Hud = preload("res://scripts/presentation/hud.gd")
const PlayerControls = preload("res://scripts/presentation/player_controls.gd")
const TickPump = preload("res://addons/hatchery/core/tick_pump.gd")
const LaunchArgs = preload("res://addons/hatchery/settings/launch_args.gd")
var world: RefCounted
var save_state: RefCounted
var slot: int = 1
var overwrite_ok: bool = false
var view: Node2D
var camera: Camera2D
var hud: Control
var paused: bool = true
var resume_after_rescue: bool = false
var pump := TickPump.new()
var defeat_shown: bool = false
var storage_enabled: bool = true
var controls := PlayerControls.new()


## Keeps the 1280x720 view inside the area, centring any axis the area is smaller than.
func _camera_target() -> Vector2:
	var bounds := Vector2(float(world.catalog.bounds[0]), float(world.catalog.bounds[1]))
	var focus: Vector2 = world.player.pos + Vector2(0, -40)
	return Vector2(clampf(focus.x, minf(640.0, bounds.x / 2.0), maxf(bounds.x - 640.0, bounds.x / 2.0)), clampf(focus.y, minf(360.0, bounds.y / 2.0), maxf(bounds.y - 360.0, bounds.y / 2.0)))


func _ready() -> void:
	var data: Dictionary = Catalog.read()
	if data.is_empty():
		get_tree().quit(1)
		return
	world = World.new(data)
	save_state = SaveState.new(data, SaveSlots.path(slot))
	storage_enabled = not LaunchArgs.has("no-save")
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
	hud.load_preferences(storage_enabled)
	hud.requested.connect(command)
	hud.rescue_requested.connect(dismiss_rescue)
	hud.production_requested.connect(configure_production)
	hud.medicine_requested.connect(configure_medicine)
	hud.medicine_cancelled.connect(cancel_medicine)
	hud.production_cancelled.connect(cancel_production)
	hud.work_cancelled.connect(cancel_work)
	hud.work_located.connect(locate_work)
	hud.work_assigned.connect(assign_work)
	hud.work_prioritised.connect(prioritise_work)
	hud.assignment_requested.connect(assign_survivor)
	hud.equipment_requested.connect(equip)
	hud.show_menu(true)
	hud.refresh(world, paused)
	slot = clampi(int(hud.settings.values.slot), 1, SaveSlots.COUNT)
	save_state = SaveState.new(world.catalog, SaveSlots.path(slot))
	save_state.store.enabled = storage_enabled
	hud.slot_button.text = SaveSlots.summary(slot)
	# Loading is explicit, so opening the prototype cannot overwrite a run.
	if storage_enabled:
		_open_saved_area()
		save_state.store.load_data()
		if not save_state.store.last_error.is_empty():
			hud.menu_status.text = save_state.store.last_error


func _process(dt: float) -> void:
	if world == null:
		return
	if world.travel_requested != "":
		_travel(world.travel_requested)
	if world.campaign_ended:
		paused = true
	if world.defeat_pending:
		paused = true
		if not defeat_shown:
			hud.menu_status.text = ""
			defeat_shown = true
	if not world.rescue_intro.is_empty():
		if not paused:
			resume_after_rescue = true
		paused = true
	if not paused:
		world.move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		world.working = Input.is_action_pressed("work")
		world.interacting = Input.is_action_pressed("interact")
		pump.tick_seconds = float(world.balance.step)
		pump.run(minf(dt, 0.2), _step_world)
	var target := _camera_target()
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
	view.queue_redraw()
	hud.refresh(world, paused, dt)


## One fixed step of the street. A defeat or a rescue stops this frame's steps.
func _step_world() -> bool:
	world.step(pump.tick_seconds)
	if world.defeat_pending:
		paused = true
		hud.menu_status.text = ""
		defeat_shown = true
		return false
	if not world.rescue_intro.is_empty():
		resume_after_rescue = true
		paused = true
		return false
	return true


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
				KEY_M:
					command("town")
	if not paused and event.is_action_pressed("interact"):
		world.interact()
	elif not paused and event.is_action_released("interact"):
		world.release_interact()


func command(value: String) -> void:
	if value != "save":
		overwrite_ok = false
	if world.campaign_ended:
		if value == "resume":
			world.campaign_ended = false
			paused = false
			hud.refresh(world, false)
			return
		if value != "new":
			paused = true
			hud.refresh(world, true)
			return
	if world.defeat_pending and value not in ["recover", "load"]:
		paused = true
		hud.refresh(world, true)
		return
	if not world.rescue_intro.is_empty() and value in ["resume", "menu", "team", "work", "town"]:
		paused = true
		hud.refresh(world, true)
		return
	match value:
		"recover":
			if Defeat.recover(world):
				defeat_shown = false
				pump.reset()
				controls = PlayerControls.new()
				camera.position = _camera_target()
				camera.force_update_scroll()
				hud.menu_status.text = ""
				paused = false
				hud.refresh(world, false)
		"work":
			if world.clinic.done or Facility.state(world, "munitions").looted or ConstructionMenu.available(world):
				paused = true
				hud.refresh(world, true)
				hud.show_menu()
				hud.show_section("Work")
		"town":
			paused = true
			hud.show_menu()
			hud.show_section("Town")
			hud.refresh(world, true)
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
		"slot":
			slot = SaveSlots.next(slot)
			save_state = SaveState.new(world.catalog, SaveSlots.path(slot))
			save_state.store.enabled = storage_enabled
			hud.settings.set_value("slot", slot)
			hud.settings.save_settings()
			hud.slot_button.text = SaveSlots.summary(slot)
			hud.menu_status.text = "Save and Load now use slot %d." % slot
		"save":
			# A slot holding a longer run than this one is probably someone else's progress: ask first.
			if not overwrite_ok and SaveSlots.seconds(save_state.store.path) > AreaTravel.played(world) + 1.0:
				overwrite_ok = true
				hud.menu_status.text = "%s holds a longer run than this one. Press Save again to overwrite it." % SaveSlots.summary(slot)
				return
			var okay: bool = save_state.store.save_data(save_state.snapshot(world))
			hud.menu_status.text = ("Street saved to slot %d. Previous good save retained as backup." % slot) if okay else save_state.store.last_error
			hud.slot_button.text = SaveSlots.summary(slot)
		"load":
			_open_saved_area()
			var data: Dictionary = save_state.store.load_data()
			if data.is_empty():
				hud.menu_status.text = "No saved street yet." if save_state.store.last_error.is_empty() else save_state.store.last_error
			else:
				var restored: RefCounted = save_state.restore(data)
				if restored == null:
					hud.menu_status.text = "That save could not be restored. Your current street is unchanged."
					return
				world = restored
				defeat_shown = false
				resume_after_rescue = false
				controls = PlayerControls.new()
				view.world = world
				pump.reset()
				hud.menu_status.text = "Street restored. Resume when ready."
				hud.refresh(world, paused)
		"new":
			if not save_state.store.keep_previous():
				hud.menu_status.text = save_state.store.last_error
				return
			var first: Dictionary = Catalog.read()
			_enter(World.new(first), first)
			hud.menu_status.text = "New street ready. Your saved street is preserved until you save."


## Moves the community through the exit. The area left behind is frozen in the save, so it can be returned to.
func _travel(area_id: String) -> void:
	world.travel_requested = ""
	var data: Dictionary = Catalog.read(area_id)
	var arrived: RefCounted = AreaTravel.travel(world, save_state, data) if not data.is_empty() else null
	if arrived == null:
		world.note("The way to %s is not ready." % area_id)
		return
	_enter(arrived, data)
	paused = true
	hud.show_menu(true)
	hud.pause_title.text = str(data.area.name).to_upper()
	hud.first_button.text = "Step out"
	hud.menu_status.text = "Arrived. Save to keep this place; resume when ready."


func _enter(next: RefCounted, data: Dictionary) -> void:
	save_state = SaveState.new(data, SaveSlots.path(slot))
	save_state.store.enabled = storage_enabled
	world = next
	view.world = world
	defeat_shown = false
	controls = PlayerControls.new()
	pump.reset()
	camera.position = _camera_target()
	camera.force_update_scroll()


## A save belongs to one area; load that area's content before reading it.
func _open_saved_area() -> void:
	if not FileAccess.file_exists(save_state.store.path):
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_state.store.path))
	if not raw is Dictionary or not raw.get("area") is String or raw.area == world.catalog.area.id:
		return
	var data: Dictionary = Catalog.read(raw.area)
	if not data.is_empty():
		_enter(World.new(data), data)


func assign_survivor(id: String, task: String) -> void:
	var okay: bool = world.assign_survivor(id, task)
	hud.menu_status.text = "" if okay else world.messages.back()
	hud.refresh(world, paused)


func equip(id: String, slot: String, item: String) -> void:
	var okay: bool = Equipment.equip(world, id, slot, item)
	hud.menu_status.text = "" if okay else world.messages.back()
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
	if Greenhouse.cancel(world, socket) or Clinic.cancel(world, socket) or Neighbourhood.cancel(world, socket) or Restoration.cancel(world, socket) or Roadworks.cancel(world, socket) or Repairs.cancel(world, socket):
		hud.menu_status.text = "Work cancelled"
		hud.refresh(world, paused)


func prioritise_work(socket: String, value: bool) -> void:
	if WorkOrders.prioritise(world, socket, value):
		hud.menu_status.text = ""
		hud.refresh(world, paused)


func locate_work(socket: String) -> void:
	var order: Dictionary = WorkOrders.current(world, socket)
	if not WorkOrders.pending(order):
		return
	command("town")
	hud.town_map.locate(world, Vector2(order.stand[0], order.stand[1]))


func assign_work(socket: String, id: String) -> void:
	var okay: bool = Jobs.assign_order(world, socket, id)
	hud.menu_status.text = "" if okay else world.messages.back()
	hud.refresh(world, paused)


func dismiss_rescue(task: String) -> void:
	if Roster.dismiss(world, task):
		paused = not resume_after_rescue
		resume_after_rescue = false
		hud.refresh(world, paused)


func configure_medicine(mode: String, target: int, reserve: int) -> void:
	if Medicine.configure(world, mode, target, reserve):
		hud.menu_status.text = ""
		hud.refresh(world, paused)


func cancel_medicine() -> void:
	if Medicine.cancel(world):
		hud.menu_status.text = ""
		hud.refresh(world, paused)
