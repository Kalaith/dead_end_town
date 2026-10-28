extends RefCounted
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const NeighbourhoodChecks = preload("res://tools/checks/checks_neighbourhood.gd")


static func prepared() -> RefCounted:
	var w := World.new(Catalog.read())
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	for id: String in ["garden", "library", "garage"]:
		w.claim(id)
	NeighbourhoodChecks.integrate(w)
	w.workshop.started = true
	w.workshop.progress = float(w.balance.workshop_seconds)
	w.workshop.done = true
	w.workshop.armour_started = true
	w.workshop.armour_progress = float(w.balance.armour_seconds)
	w.workshop.armour_done = true
	w.player.pos = Vector2(1080, 800)
	for a: Dictionary in w.survivors:
		a.pos = Vector2(1080, 800)
	return w


func check_unique_equipment_moves_between_any_person_and_storage() -> String:
	var w: RefCounted = prepared()
	var stock: int = w.materials
	if not Equipment.equip(w, "you", "weapon", "sword") or not Equipment.equip(w, "mara", "protection", "iron") or not Equipment.equip(w, "mara", "shield", "shield"):
		return "Player/Mara cannot choose restored equipment."
	if Equipment.equip(w, "paige", "weapon", "sword") or Equipment.equip(w, "paige", "protection", "iron"):
		return "One unique item equipped on two people."
	Equipment.equip(w, "mara", "protection", "none")
	if not Equipment.equip(w, "paige", "protection", "iron") or w.equipment.shield != "mara":
		return "Transfer moved an unrelated item or failed."
	Equipment.equip(w, "you", "weapon", "crowbar")
	if w.equipment.sword != "" or w.equipment.crowbar != "you":
		return "Weapon swap failed to return the previous weapon."
	var save := SaveState.new(w.catalog)
	var loaded: RefCounted = save.restore(JSON.parse_string(JSON.stringify(save.snapshot(w))))
	return "Loadout reload lost items or spent supplies" if loaded == null or loaded.equipment != w.equipment or w.materials != stock else ""


func check_equipping_refuses_remote_downed_unrestored_and_disconnected_changes() -> String:
	var w: RefCounted = prepared()
	w.survivors[0].pos = Vector2(360, 350)
	if Equipment.equip(w, "mara", "weapon", "sword"):
		return "Remote loadout changed."
	w.survivors[0].pos = w.player.pos
	w.survivors[0].hp = 0.0
	if Equipment.equip(w, "mara", "protection", "iron"):
		return "Downed actor changed equipment."
	w.survivors[0].hp = 100.0
	w.workshop.armour_done = false
	if Equipment.equip(w, "you", "weapon", "sword"):
		return "Unrestored cache provided a weapon."
	w.workshop.armour_done = true
	w.properties.home.claimed = false
	if Equipment.equip(w, "you", "shield", "shield") or w.equipment != Equipment.initial():
		return "Unsafe equipment change changed ownership."
	return ""


func check_weapon_choices_change_targets_damage_reach_and_cadence() -> String:
	var w: RefCounted = prepared()
	w.player.pos = Vector2(1080, 800)
	w.aim = Vector2.LEFT
	Equipment.equip(w, "you", "weapon", "sword")
	for i: int in range(3):
		w.zombies[i].hp = 60.0
		w.zombies[i].pos = w.player.pos + Vector2(-40, (i - 1) * 12)
	w.attack()
	var hit: int = 0
	for i: int in range(3):
		if w.zombies[i].hp < 60:
			hit += 1
	if hit != 2 or not is_equal_approx(w.player.cooldown, 0.65):
		return "Sword does not cleave exactly two with its own cadence."
	for z: Dictionary in w.zombies:
		z.hp = 0.0
	Equipment.equip(w, "you", "weapon", "crowbar")
	w.player.cooldown = 0.0
	w.zombies[0].hp = 60.0
	w.zombies[0].pos = w.player.pos + Vector2.LEFT * 80
	w.attack()
	if w.zombies[0].hp != 10 or not is_equal_approx(w.player.cooldown, 0.85):
		return "Crowbar lacks its longer single-target hit and slower recovery."
	return ""


func check_protection_and_shield_apply_to_player_and_mara_independently() -> String:
	var w: RefCounted = prepared()
	Equipment.equip(w, "you", "protection", "iron")
	Equipment.equip(w, "mara", "shield", "shield")
	w.player.facing = Vector2.RIGHT
	w.survivors[0].facing = Vector2.RIGHT
	var base: float = float(w.balance.zombie_damage)
	if not is_equal_approx(Combat.incoming_damage(w, w.player, w.player.pos + Vector2.LEFT), base * 0.5):
		return "Player lacks iron protection."
	if not is_equal_approx(Combat.incoming_damage(w, w.survivors[0], w.survivors[0].pos + Vector2.RIGHT), base * 0.5) or not is_equal_approx(Combat.incoming_damage(w, w.survivors[0], w.survivors[0].pos + Vector2.LEFT), base):
		return "Shield does not independently protect Mara's front."
	var start: Vector2 = w.player.pos
	w.move_input = Vector2.RIGHT
	w.step(0.05)
	return "Player heavy armour speed penalty absent" if absf(w.player.pos.distance_to(start) - float(w.balance.player_speed) * 0.8 * 0.05) > 0.01 else ""


func check_equipment_migration_and_invalid_ownership() -> String:
	var w: RefCounted = prepared()
	var save := SaveState.new(w.catalog)
	var old: Dictionary = save.snapshot(w)
	old.schema_version = 8
	old.erase("equipment")
	old.workshop.equipped = true
	var upgraded: Dictionary = save.migrate(old)
	if upgraded.is_empty() or upgraded.equipment.iron != "paige" or upgraded.equipment.shield != "paige" or upgraded.equipment.sword != "":
		return "Old fitted armour did not migrate to the same unique wearer."
	for mutation: Dictionary in [{"iron": "unknown"}, {"iron": "mara", "shield": "paige"}, {"sword": "you", "crowbar": "you"}]:
		var raw: Dictionary = save.snapshot(w)
		raw.equipment.merge(mutation, true)
		# Different valid owners are allowed; the compatibility flag must still agree.
		if mutation.has("iron") and mutation.iron == "mara":
			raw.workshop.equipped = true
		if save.valid(raw):
			return "Malformed equipment accepted: " + str(mutation)
	return ""
