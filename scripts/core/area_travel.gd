extends RefCounted
## Moves the community between areas. Each area's whole state is frozen in the save while the player is elsewhere,
## so the same exit works both ways. People, equipment and a capped amount of stock travel; the rest stays behind.
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Boss = preload("res://scripts/sim/boss.gd")
const Equipment = preload("res://scripts/sim/equipment.gd")
const Jobs = preload("res://scripts/sim/jobs.gd")
const Routes = preload("res://scripts/sim/routes.gd")
const ARRIVAL_SPACING: float = 40.0


## Returns the world for `to_data`'s area, or null when its frozen record is unusable (nothing is changed then).
static func travel(world: RefCounted, saves: RefCounted, to_data: Dictionary) -> RefCounted:
	var cap: int = int(world.balance.area_carry_cap)
	var carried: Dictionary = {"materials": mini(world.materials, cap), "food": mini(world.food, cap), "medicine": mini(world.medicine, cap), "bullets": mini(int(world.firearms.bullets), cap)}
	var frozen: Dictionary = world.frozen.duplicate(true)
	var destination: RefCounted
	var returning: bool = frozen.has(to_data.area.id)
	if returning:
		destination = SaveState.new(to_data, saves.store.path).restore(frozen[to_data.area.id])
		if destination == null:
			return null
		frozen.erase(to_data.area.id)
	else:
		destination = World.new(to_data)
	var record: Dictionary = saves.snapshot(world)
	record.frozen = {}
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
	if world.firearms.owned and "firearm" not in destination.unlocks:
		destination.unlocks.append("firearm")
	for item: String in Equipment.GATED:
		if Equipment.unlocked(world, item) and item not in destination.unlocks:
			destination.unlocks.append(item)
	destination.player.hp = world.player.hp
	_arrive(world, destination)
	destination.note("%s / Arrived. Your team came with you." % str(to_data.area.name))
	return destination


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
