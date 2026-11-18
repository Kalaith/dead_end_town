extends RefCounted
## Moves the community between areas. Each area's whole state is frozen in the save while the player is elsewhere,
## so the same exit works both ways. People, equipment and a capped amount of stock travel; the rest stays behind.
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const Roster = preload("res://scripts/sim/roster.gd")
const ARRIVAL_SPACING: float = 40.0


## Returns the world for `to_data`'s area, or null when its frozen record is unusable (nothing is changed then).
static func travel(world: RefCounted, saves: RefCounted, to_data: Dictionary) -> RefCounted:
	var cap: int = int(world.balance.area_carry_cap)
	var carried: Dictionary = {"materials": mini(world.materials, cap), "food": mini(world.food, cap), "medicine": mini(world.medicine, cap), "bullets": mini(int(world.firearms.bullets), cap)}
	var frozen: Dictionary = world.frozen.duplicate(true)
	var total: float = played(world)
	var destination: RefCounted
	var returning: bool = frozen.has(to_data.area.id)
	var away: float = 0.0
	if returning:
		destination = SaveState.new(to_data, saves.store.path).restore(frozen[to_data.area.id])
		if destination == null:
			return null
		away = total - float(frozen[to_data.area.id].get("left_total", total))
		frozen.erase(to_data.area.id)
	else:
		destination = World.new(to_data)
	var record: Dictionary = saves.snapshot(world)
	record.frozen = {}
	record.left_total = total
	record.materials = world.materials - int(carried.materials)
	record.food = world.food - int(carried.food)
	record.medicine = world.medicine - int(carried.medicine)
	record.firearms.bullets = int(world.firearms.bullets) - int(carried.bullets)
	record.player.hp = minf(float(record.player.hp), float(world.balance.player_health))
	frozen[world.area] = record
	destination.frozen = frozen
	destination.materials += int(carried.materials)
	destination.food += int(carried.food)
	destination.medicine += int(carried.medicine)
	destination.firearms.owned = world.firearms.owned
	destination.firearms.bullets += int(carried.bullets)
	destination.equipment = world.equipment.duplicate(true)
	destination.workshop.equipped = world.workshop.equipped
	# What the community has learned to expect travels with it, so later areas can use those kinds.
	for kind: Variant in world.pressure.taught:
		if kind not in destination.pressure.taught:
			destination.pressure.taught.append(kind)
	if world.firearms.owned and "firearm" not in destination.unlocks:
		destination.unlocks.append("firearm")
	for item: String in Equipment.GATED:
		if Equipment.unlocked(world, item) and item not in destination.unlocks:
			destination.unlocks.append(item)
	destination.player.hp = world.player.hp
	_arrive(world, destination)
	# The team was just replaced by the travellers, so look again for anyone a lot here still owes.
	Roster.catch_up(destination)
	destination.note("%s / Arrived. Your team came with you." % str(to_data.area.name))
	_regrow(destination, away)
	var left: String = Boss.stored(record)
	if not left.is_empty():
		destination.note("Left behind in %s: %s. Go back for it when you need it." % [str(world.catalog.area.name), left])
	return destination


## Seconds played across every area, so time spent elsewhere counts as time away from this one.
static func played(world: RefCounted) -> float:
	var total: float = float(world.elapsed)
	for record: Variant in world.frozen.values():
		total += float(record.get("elapsed", 0.0))
	return total


## Times the team has gone down across every area, for the closing line.
static func downs(world: RefCounted) -> int:
	var total: int = int(world.downs)
	for record: Variant in world.frozen.values():
		total += int(record.get("downs", 0))
	return total


## A finished garden keeps growing food and a restored clinic keeps making medicine while you are away: one unit per
## `away_food_seconds` / `away_medicine_seconds`, never above the carry cap.
static func _regrow(destination: RefCounted, away: float) -> void:
	if away <= 0.0:
		return
	var cap: int = int(destination.balance.area_carry_cap)
	if destination.garden_done:
		var grown: int = mini(int(away / float(destination.balance.away_food_seconds)), maxi(0, cap - destination.food))
		if grown > 0:
			destination.food += grown
			destination.note("While you were away the garden grew %d food." % grown)
	# Leave a settlement alone long enough and raiders find the gate.
	if away >= float(destination.balance.away_siege_seconds):
		var gate: float = float(destination.properties.home.gate_hp)
		var battered: float = floorf(gate * float(destination.balance.away_siege_factor))
		if battered < gate:
			destination.properties.home.gate_hp = battered
			destination.note("While you were away raiders battered the home gate. Repair it before you rest.")
	if destination.clinic.done:
		var made: int = mini(int(away / float(destination.balance.away_medicine_seconds)), maxi(0, cap - destination.medicine))
		if made > 0:
			destination.medicine += made
			destination.note("While you were away the clinic made %d medicine." % made)


## Going forward arrives at the destination's entrance; going back arrives at the exit that was used.
static func _door(world: RefCounted, destination: RefCounted) -> Vector2:
	var ids: Array = world.catalog.areas.map(func(entry: Dictionary) -> String: return str(entry.id))
	var forward: bool = ids.find(destination.area) > ids.find(world.area)
	if forward and destination.catalog.has("entrance"):
		return Routes.rectangle(destination.catalog.entrance.rect).get_center()
	if not forward and Boss.configured(destination.catalog):
		return Boss.exit_rect(destination.catalog).get_center()
	return Routes.point(destination.balance.player_start)


static func _arrive(world: RefCounted, destination: RefCounted) -> void:
	var door: Vector2 = _door(world, destination)
	destination.player.pos = door
	destination.player.anchor = door
	destination.survivors.clear()
	for i: int in range(world.survivors.size()):
		var a: Dictionary = world.survivors[i].duplicate(true)
		var spot: Vector2 = door + Vector2(ARRIVAL_SPACING * float(i + 1), ARRIVAL_SPACING)
		a.pos = spot
		a.anchor = spot
		a.order = "Follow"
		a.activity = "Ready"
		a.job = ""
		Jobs.initialise(a, str(world.survivors[i].duty.role))
		destination.survivors.append(a)
