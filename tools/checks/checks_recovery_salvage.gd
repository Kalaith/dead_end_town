extends RefCounted
const RecoveryChecks = preload("res://tools/checks/checks_recovery.gd")
const EquipmentChecks = preload("res://tools/checks/checks_equipment.gd")
const RecoverySalvage = preload("res://scripts/sim/recovery_salvage.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Restoration = preload("res://scripts/sim/restoration.gd")


func check_player_only_recovery_work_persists_separate_sites_and_stops_for_danger() -> String:
	var w: RefCounted = RecoveryChecks.quiet()
	w.materials = 0
	w.player.pos = Vector2(180, 350)
	w.assign_survivor("mara", "builder")
	RecoverySalvage.step(w, 20.0)
	if w.materials != 0 or w.recovery_salvage.home != 0:
		return "Idle player or automatic builder produced emergency supplies."
	w.working = true
	RecoverySalvage.step(w, 10.0)
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = Vector2(220, 350)
	RecoverySalvage.step(w, 20.0)
	if w.recovery_salvage.home != 10.0 or w.materials != 0:
		return "Danger advanced recovery salvage."
	w.zombies[0].hp = 0.0
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	if loaded == null or loaded.recovery_salvage.home != 10.0:
		return "Partial recovery work failed JSON reload."
	loaded.working = true
	loaded.player.pos = Vector2(30, 610)
	RecoverySalvage.step(loaded, 5.0)
	if loaded.recovery_salvage.west != 5.0 or loaded.recovery_salvage.home != 10.0:
		return "Changing piles transferred partial work."
	loaded.player.pos = Vector2(180, 350)
	RecoverySalvage.step(loaded, 10.0)
	return "Paid-time recovery did not deliver exactly two" if loaded.materials != 2 or loaded.recovery_salvage.home != 0 else ""


func check_refundable_projects_share_the_cap_through_repeated_approval_and_cancellation() -> String:
	var w: RefCounted = RecoveryChecks.quiet()
	w.claim("garden")
	w.materials = 24
	for i: int in range(12):
		w.player.pos = Vector2(1080, 350)
		if not Restoration.approve(w, "garden"):
			return "Recovery cap fixture failed its explicit approval."
		w.player.pos = Vector2(30, 610)
		w.working = true
		RecoverySalvage.step(w, 20.0)
		if RecoverySalvage.held(w) != 24 or w.materials != 16:
			return "An approved refundable bundle freed false recovery capacity."
		Restoration.cancel(w, "restore:garden")
		if w.materials != 24:
			return "Approval/cancellation created more than the combined cap."
	w.player.pos = Vector2(1080, 350)
	Restoration.approve(w, "garden")
	w.working = true
	Restoration.step(w, "garden", 4.0)
	w.player.pos = Vector2(30, 610)
	RecoverySalvage.step(w, 20.0)
	if RecoverySalvage.held(w) != 24 or w.materials != 17:
		return "Partial construction did not use its exact current cancellation return."
	Restoration.cancel(w, "restore:garden")
	return "Partial-order cancellation exceeded cap" if w.materials != 24 else ""


func check_output_clamps_to_one_and_never_deletes_a_cache_above_cap() -> String:
	var w: RefCounted = RecoveryChecks.quiet()
	w.player.pos = Vector2(30, 610)
	w.working = true
	w.materials = 23
	RecoverySalvage.step(w, 20.0)
	if w.materials != 24 or w.recovery_salvage.west != 0:
		return "Recovery output overshot the last one-material space."
	w.materials = 22
	RecoverySalvage.step(w, 19.0)
	w.materials += 32
	RecoverySalvage.step(w, 1.0)
	if w.materials != 54 or w.recovery_salvage.west != 19.0:
		return "Above-cap finite cache was deleted or enabled another output."
	w.materials = 14
	RecoverySalvage.step(w, 1.0)
	return "Lower stock failed to resume partial work" if w.materials != 16 or w.recovery_salvage.west != 0 else ""


func check_manual_recovery_work_never_also_repairs_the_nearby_road_line() -> String:
	var w: RefCounted = EquipmentChecks.prepared()
	w.player.pos = Vector2(30, 610)
	w.materials = 6
	w.roadworks.home_west.hp = 120.0
	w.working = true
	for i: int in range(400):
		w.step(0.05)
	if w.materials != 8 or w.roadworks.home_west.hp != 120.0:
		return "One R input also spent recovery materials on the nearby barricade."
	w.provisions.hungry = true
	w.food = 0
	for i: int in range(200):
		w.step(0.05)
	return "Recovery work ignored shortage labour rate" if not is_equal_approx(float(w.recovery_salvage.west), 6.0) else ""


func check_schema_twenty_five_keeps_pending_defeat_and_grants_no_free_scrap() -> String:
	var w: RefCounted = RecoveryChecks.quiet()
	w.player.hp = 0.0
	w.step(0.05)
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 25
	old.erase("recovery_salvage")
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(old)))
	if loaded == null or not loaded.defeat_pending or loaded.materials != w.materials or loaded.recovery_salvage.home != 0 or loaded.recovery_salvage.west != 0:
		return "Salvage migration lost defeat or granted work/materials."
	var bad: Dictionary = save.snapshot(loaded)
	bad.recovery_salvage.home = 20.0
	return "Unpaid terminal recovery progress passed validation" if save.valid(bad) else ""
