extends Node2D
const Medicine = preload("res://scripts/sim/medicine.gd")
const Facility = preload("res://scripts/sim/facility.gd")
const Defeat = preload("res://scripts/sim/defeat.gd")
const Greenhouse = preload("res://scripts/sim/greenhouse.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")
const Roster = preload("res://scripts/sim/roster.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const Tips = preload("res://scripts/sim/tips.gd")
const VanRepair = preload("res://scripts/sim/van_repair.gd")
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
const Access = preload("res://scripts/presentation/access.gd")
const StreetAudio = preload("res://scripts/presentation/street_audio.gd")
const ScreenFit = preload("res://addons/hatchery/settings/screen_fit.gd")
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
var audio: Node


## Keeps the visible view inside the area, centring any axis the area is smaller than.
func _camera_target() -> Vector2:
	var bounds := Vector2(float(world.catalog.bounds[0]), float(world.catalog.bounds[1]))
	var focus: Vector2 = world.player.pos + Vector2(0, -40)
	var half: Vector2 = get_viewport().get_visible_rect().size / 2.0
	return Vector2(clampf(focus.x, minf(half.x, bounds.x / 2.0), maxf(bounds.x - half.x, bounds.x / 2.0)), clampf(focus.y, minf(half.y, bounds.y / 2.0), maxf(bounds.y - half.y, bounds.y / 2.0)))


func _ready() -> void:
	ScreenFit.watch(get_tree().root)
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
	camera.position = get_viewport().get_visible_rect().size / 2.0 + Vector2(0, 5)
	add_child(camera)
	audio = StreetAudio.new()
	add_child(audio)
	audio.heard.connect(func(cue: String, caption: String, pos: Vector2) -> void: hud.captions.add(cue, caption, pos, world.player.pos))
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	canvas.add_child(hud)
	hud.load_preferences(storage_enabled)
	hud.requested.connect(command)
	hud.slot_named.connect(name_slot)
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
	_show_slot()
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
	audio.listen(world, paused, dt)
	var target := _camera_target()
	camera.position = target if Access.reduce_motion else camera.position.lerp(target, 1.0 - exp(-dt * 8))
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
	if hud.settings_host.is_open():
		return
	if event.is_action_pressed("pause"):
		command("menu")
		get_viewport().set_input_as_handled()
		return
	if not paused and not event.is_echo():
		for entry: Array in SHORTCUTS:
			if event.is_action_pressed(entry[0]):
				_shortcut(str(entry[1]))
				get_viewport().set_input_as_handled()
				return
	if not paused and event.is_action_pressed("interact"):
		world.interact()
	elif not paused and event.is_action_released("interact"):
		world.release_interact()


## Rebindable shortcuts (project.godot actions) -> what they do.
const SHORTCUTS: Array = [["order_follow", "Follow"], ["order_hold", "Hold"], ["order_engage", "Engage"], ["order_home", "Home"], ["salvage", "salvage"], ["road_guard", "guard"], ["team", "team"], ["work_board", "work"], ["town_map", "town"]]


func _shortcut(value: String) -> void:
	match value:
		"Follow", "Hold", "Engage", "Home":
			world.order(value)
		"salvage":
			world.salvage()
		"guard":
			world.post_road_guard()
		_:
			command(value)


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
			Tips.saw_board(world)
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
			_show_slot()
			hud.menu_status.text = "Save and Load now use slot %d." % slot
		"delete":
			var gone: bool = SaveSlots.remove(slot) if storage_enabled else false
			hud.settings.set_value(SaveSlots.name_key(slot), "")
			hud.settings.save_settings()
			_show_slot()
			if not storage_enabled:
				hud.menu_status.text = "Saving is off in this run, so nothing was deleted."
			else:
				hud.menu_status.text = ("Slot %d deleted. Your current street is unchanged." % slot) if gone else ("Slot %d was already empty." % slot)
		"save":
			# A slot holding a longer run than this one is probably someone else's progress: ask first.
			if not overwrite_ok and SaveSlots.seconds(save_state.store.path) > AreaTravel.played(world) + 1.0:
				overwrite_ok = true
				hud.menu_status.text = "%s holds a longer run than this one. Press Save again to overwrite it." % _slot_summary()
				return
			var okay: bool = save_state.store.save_data(save_state.snapshot(world))
			hud.menu_status.text = ("Street saved to slot %d. Previous good save retained as backup." % slot) if okay else save_state.store.last_error
			_show_slot()
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
func _slot_summary() -> String:
	return SaveSlots.summary(slot, "", str(hud.settings.values.get(SaveSlots.name_key(slot), "")))


func _show_slot() -> void:
	hud.slot_button.text = _slot_summary()
	hud.slot_controls.show_name(str(hud.settings.values.get(SaveSlots.name_key(slot), "")))


## The player named the chosen slot; an empty name clears it.
func name_slot(text: String) -> void:
	var label: String = SaveSlots.clean_name(text)
	if label == str(hud.settings.values.get(SaveSlots.name_key(slot), "")):
		return
	hud.settings.set_value(SaveSlots.name_key(slot), label)
	hud.settings.save_settings()
	_show_slot()
	hud.menu_status.text = ("Slot %d is now called %s." % [slot, label]) if not label.is_empty() else ("Slot %d has no name now." % slot)


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
	if Greenhouse.cancel(world, socket) or Clinic.cancel(world, socket) or Neighbourhood.cancel(world, socket) or Restoration.cancel(world, socket) or Roadworks.cancel(world, socket) or Repairs.cancel(world, socket) or VanRepair.cancel(world, socket):
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
