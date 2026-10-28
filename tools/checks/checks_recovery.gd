extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Carrying = preload("res://scripts/sim/carrying.gd")
const HomeRest = preload("res://scripts/sim/home_rest.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Firearms = preload("res://scripts/sim/firearms.gd")
const EquipmentChecks = preload("res://tools/checks/checks_equipment.gd")
const ClinicChecks = preload("res://tools/checks/checks_clinic.gd")
const Clinic = preload("res://scripts/sim/clinic.gd")


static func quiet() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	return w


func check_casualty_hold_has_priority_and_danger_or_release_cannot_lift() -> String:
	var w: RefCounted = quiet()
	w.player.pos = Vector2(360, 465)
	w.survivors[0].pos = Vector2(360, 440)
	w.survivors[0].hp = 0.0
	var gate: bool = w.properties.home.open
	w.interact()
	w.interacting = true
	Carrying.step(w, 1.0)
	w.release_interact()
	if Carrying.occupied(w) or w.properties.home.open != gate or w.carry.progress != 0:
		return "Short casualty input lifted or toggled the nearby gate."
	w.interact()
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = Vector2(420, 440)
	Carrying.step(w, 3.0)
	if Carrying.occupied(w) or w.carry.progress != 0:
		return "Danger allowed a casualty lift."
	w.zombies[0].hp = 0.0
	Carrying.step(w, 2.0)
	return "Clear two-second hold failed to lift once" if w.carry.patient != "mara" else ""


func check_carrying_blocks_both_attack_paths_and_combines_armour_with_movement_slow() -> String:
	var w: RefCounted = EquipmentChecks.prepared()
	w.claim("residence")
	Equipment.equip(w, "you", "protection", "iron")
	w.player.pos = Vector2(1500, 580)
	w.survivors[0].pos = Vector2(1520, 580)
	w.survivors[0].hp = 0.0
	w.interact()
	w.interacting = true
	Carrying.step(w, 2.0)
	w.zombies[0].hp = 100.0
	w.zombies[0].pos = Vector2(1540, 580)
	var bullets: int = w.firearms.bullets
	Combat.strike(w, w.player, Vector2.RIGHT)
	w.attack()
	if Firearms.shoot(w) or w.shoot() or w.zombies[0].hp != 100 or w.firearms.bullets != bullets:
		return "Carrying allowed damage or spent ammunition."
	w.zombies[0].hp = 0.0
	w.move_input = Vector2.RIGHT
	var before: Vector2 = w.player.pos
	for i: int in range(20):
		w.step(0.05)
	var expected: float = float(w.balance.player_speed) * float(w.balance.carry_speed_factor) * float(w.balance.armour_speed_multiplier)
	if absf(w.player.pos.x - before.x - expected) > 0.01 or w.survivors[0].pos != w.player.pos:
		return "Carry/armour speed or attachment drift: moved=%s expected=%s patient=%s carrier=%s carry=%s" % [w.player.pos.x - before.x, expected, w.survivors[0].pos, w.player.pos, w.carry]
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	return "Carried casualty or equipment failed reload" if loaded == null or loaded.carry.patient != "mara" or loaded.equipment != w.equipment else ""


func check_player_physically_carries_a_casualty_home_and_drops_only_at_clear_shelter() -> String:
	var w: RefCounted = quiet()
	w.properties.home.open = true
	w.rebuild_routes()
	w.player.pos = Vector2(1060, 350)
	w.survivors[0].pos = Vector2(1080, 350)
	w.survivors[0].hp = 0.0
	w.interact()
	w.interacting = true
	for i: int in range(40):
		w.step(0.05)
	if not Carrying.occupied(w) or Carrying.drop(w):
		return "Lift failed or unclaimed yard accepted a casualty drop."
	w.release_interact()
	w.interacting = false
	for i: int in range(600):
		var target := Vector2(360, 350)
		if w.player.pos.distance_to(target) < 20:
			break
		var next: Vector2 = w.routes.waypoint(w.player.pos, target)
		w.move_input = w.player.pos.direction_to(next)
		w.step(0.05)
	w.move_input = Vector2.ZERO
	if w.player.pos.distance_to(Vector2(360, 350)) >= 20 or not Carrying.drop(w) or Carrying.occupied(w) or w.survivors[0].hp != 0:
		return "Casualty failed physical home journey and shelter drop."
	var save := SaveState.new(w.catalog)
	return "Dropped casualty failed save validation" if not save.valid(save.snapshot(w)) else ""


func check_home_rest_pays_once_and_only_present_patients_progress_through_reload() -> String:
	var w: RefCounted = quiet()
	w.player.pos = Vector2(360, 350)
	w.player.hp = 30.0
	w.survivors[0].hp = 0.0
	w.food = 6
	if not HomeRest.start(w) or HomeRest.start(w) or w.food != 4 or w.player.hp != 30:
		return "Home rest did not commit once without instant healing."
	HomeRest.step(w, 7.0)
	w.survivors[0].pos = Vector2(1080, 350)
	HomeRest.step(w, 8.0)
	if w.player.hp != 50 or w.survivors[0].hp != 0 or w.home_rest.patients.mara != 7.0:
		return "Absent patient advanced or received remote recovery."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null:
		return "Paid absent-patient recovery failed reload."
	loaded.survivors[0].pos = Vector2(300, 370)
	HomeRest.step(loaded, 8.0)
	if loaded.survivors[0].hp != 50 or not loaded.home_rest.patients.is_empty() or loaded.food != 4:
		return "Returning patient lost its already paid interval."
	if not HomeRest.start(loaded) or loaded.food != 2:
		return "Full healing did not require its own explicit payment."
	HomeRest.step(loaded, 15.0)
	return "Healthy team spent again or failed full heal" if loaded.player.hp != 100 or loaded.survivors[0].hp != 100 or HomeRest.start(loaded) or loaded.food != 2 else ""


func check_home_loss_and_danger_pause_paid_rest_without_a_refund_or_second_charge() -> String:
	var w: RefCounted = quiet()
	w.player.hp = 20.0
	HomeRest.start(w)
	HomeRest.step(w, 4.0)
	var food: int = w.food
	w.properties.home.claimed = false
	HomeRest.step(w, 20.0)
	w.properties.home.claimed = true
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = Vector2(400, 400)
	HomeRest.step(w, 20.0)
	if w.home_rest.patients.you != 4.0 or w.player.hp != 20 or w.food != food:
		return "Loss/danger advanced or rebilled paid rest."
	w.zombies[0].hp = 0.0
	HomeRest.step(w, 11.0)
	return "Clear home did not resume paid rest" if w.player.hp != 50 or w.food != food else ""


func check_carried_clinic_patient_keeps_paid_progress_until_put_down() -> String:
	var w: RefCounted = ClinicChecks.connected_clinic()
	var june: Dictionary = Equipment.person(w, "june")
	june.hp = 0.0
	Clinic.treat(w)
	w.working = true
	Clinic.step(w, 4.0)
	w.interact()
	w.interacting = true
	Carrying.step(w, 2.0)
	w.working = true
	Clinic.step(w, 20.0)
	if june.hp != 0 or w.clinic.patients.june.progress != 4.0:
		return "Carried patient received clinic healing."
	if not Carrying.drop(w):
		return "Clear clinic shelter refused a casualty drop."
	w.working = true
	Clinic.step(w, 6.0)
	return "Dropped patient failed to resume prepaid treatment" if june.hp != 100 or w.medicine != 11 else ""


func check_schema_twenty_three_keeps_downed_people_and_adds_no_free_recovery() -> String:
	var w: RefCounted = quiet()
	w.survivors[0].hp = 0.0
	w.survivors[0].pos = Vector2(1080, 350)
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 23
	old.erase("carry")
	old.erase("home_rest")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or loaded.survivors[0] != w.survivors[0] or loaded.food != w.food or not loaded.home_rest.patients.is_empty() or Carrying.occupied(loaded):
		return "Recovery migration changed old patients, stock or position."
	var bad: Dictionary = save.snapshot(loaded)
	bad.carry.patient = "mara"
	if save.valid(bad):
		return "Save accepted a carried person at a different position."
	bad.carry.patient = "unknown"
	return "Save accepted an unknown casualty" if save.valid(bad) else ""
