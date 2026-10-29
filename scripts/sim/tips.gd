extends RefCounted
const Carrying = preload("res://scripts/sim/carrying.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const HomeRest = preload("res://scripts/sim/home_rest.gd")
const Salvage = preload("res://scripts/sim/salvage.gd")
const Vehicle = preload("res://scripts/sim/vehicle.gd")

## Guidance follows what the world looks like, never a fixed script: the first tip whose moment has come and whose
## lesson has not been learned is shown. Nothing here changes the game, spends anything or is saved; what cannot be read
## from saved state (walked, swung, lifted) is remembered for the session only, and a save past a minute counts as taught.
const ORDER: Array[String] = ["move", "swing", "orders", "pistol", "carry", "carry_drop", "rest", "gate_repair", "gate_open", "reclaim", "timber", "van", "arrivals"]
const WALK_DISTANCE: float = 150.0
const ZOMBIE_NEAR: float = 220.0
const INFO_SECONDS: float = 12.0
const VETERAN_SECONDS: float = 60.0


static func initial(world: RefCounted) -> Dictionary:
	return {"origin": world.player.pos, "moved": false, "swung": false, "opened": false, "lifted": false, "dropped": false, "rested": false, "ordered": false, "salvaged": false, "shot": false, "drove": false, "shown": {}, "current": ""}


## Called once per fixed step: notes the things only the moment can show.
static func step(world: RefCounted, dt: float) -> void:
	var t: Dictionary = world.tips
	if float(world.elapsed) > VETERAN_SECONDS and not t.moved:
		t.moved = true
		t.swung = true
	if world.player.pos.distance_to(t.origin) > WALK_DISTANCE:
		t.moved = true
	if float(world.player.swing) > 0:
		t.swung = true
	if world.properties.home.open:
		t.opened = true
	if Carrying.occupied(world):
		t.lifted = true
	elif t.lifted:
		t.dropped = true
	if not world.home_rest.patients.is_empty():
		t.rested = true
	if float(world.shot.left) > 0:
		t.shot = true
	if Vehicle.driving(world):
		t.drove = true
	if world.timber.values().has(true):
		t.salvaged = true
	var id: String = _current(world)
	t.current = id
	if not id.is_empty():
		t.shown[id] = float(t.shown.get(id, 0.0)) + dt


static func current(world: RefCounted) -> String:
	return str(world.tips.current)


static func text(world: RefCounted, id: String) -> String:
	return "" if id.is_empty() else str(world.catalog.tips[id])


static func _current(world: RefCounted) -> String:
	if float(world.player.hp) <= 0:
		return ""
	for id: String in ORDER:
		if _due(world, id) and not _learned(world, id):
			return id
	return ""


static func _due(world: RefCounted, id: String) -> bool:
	var t: Dictionary = world.tips
	var home: Dictionary = world.properties.home
	match id:
		"move":
			return true
		"swing":
			return t.moved and Combat.danger(world, world.player.pos, ZOMBIE_NEAR)
		"carry":
			return not Carrying.occupied(world) and not Carrying.nearby(world).is_empty()
		"carry_drop":
			return Carrying.occupied(world)
		"rest":
			return not HomeRest.next_mode(world).is_empty() and HomeRest.safe(world) and HomeRest.at_porch(world) and world.home_rest.patients.is_empty()
		"gate_repair":
			return t.moved and float(home.gate_hp) < float(world.balance.gate_health) and not t.opened
		"gate_open":
			return t.moved and not t.opened and float(home.gate_hp) >= float(world.balance.gate_health)
		"reclaim":
			return t.opened and not _reclaimed(world)
		"orders":
			return t.swung and not world.survivors.is_empty() and Combat.danger(world, world.player.pos, ZOMBIE_NEAR)
		"timber":
			return not Salvage.nearby(world).is_empty()
		"pistol":
			return world.firearms.owned and int(world.firearms.bullets) > 0 and Combat.danger(world, world.player.pos, ZOMBIE_NEAR)
		"van":
			return Vehicle.near(world)
		"arrivals":
			return bool(world.pressure.warned)
	return false


static func _learned(world: RefCounted, id: String) -> bool:
	var t: Dictionary = world.tips
	match id:
		"move":
			return t.moved
		"swing":
			return t.swung
		"carry":
			return t.lifted
		"carry_drop":
			return t.dropped
		"rest":
			return t.rested
		"gate_repair":
			return float(world.properties.home.gate_hp) >= float(world.balance.gate_health)
		"gate_open":
			return t.opened
		"reclaim":
			return _reclaimed(world)
		"orders":
			return t.ordered
		"timber":
			return t.salvaged
		"pistol":
			return t.shot
		"van":
			return t.drove
		"arrivals":
			return float(t.shown.get(id, 0.0)) >= INFO_SECONDS
	return true


static func _reclaimed(world: RefCounted) -> bool:
	for id: String in world.properties:
		if id != "home" and world.properties[id].claimed_once:
			return true
	return false
