extends RefCounted
## Personally sensed people trigger calls; sounds and memories cannot chain them.
const ZombieTypes = preload("res://scripts/sim/zombie_types.gd")
const Acoustics = preload("res://scripts/sim/noise.gd")


static func initial() -> Dictionary:
	return {"phase": "idle", "left": 0.0, "retry": 0.0, "pulse": 0.0}


static func interrupt(world: RefCounted, z: Dictionary) -> void:
	if z.get("kind") != "screecher" or z.screecher.phase != "inhale":
		return
	z.screecher.phase = "idle"
	z.screecher.left = 0.0
	z.screecher.retry = float(ZombieTypes.kind(world.catalog, z).call_retry)


static func step(world: RefCounted, z: Dictionary, target: Dictionary, dt: float) -> bool:
	if z.get("kind") != "screecher":
		return false
	var config: Dictionary = ZombieTypes.kind(world.catalog, z)
	var state: Dictionary = z.screecher
	state.retry = maxf(0.0, float(state.retry) - dt)
	state.pulse = maxf(0.0, float(state.pulse) - dt)
	if state.phase == "inhale":
		if target.is_empty():
			state.phase = "idle"
			state.left = 0.0
			return true
		z.facing = z.pos.direction_to(target.pos)
		state.left = maxf(0.0, float(state.left) - dt)
		if float(state.left) <= 0:
			state.phase = "idle"
			state.retry = float(config.call_cooldown)
			state.pulse = float(config.call_pulse)
			Acoustics.emit(world, z.id, "screecher", z.pos)
		return true
	if not target.is_empty() and float(state.retry) <= 0 and float(z.cooldown) <= 0:
		state.phase = "inhale"
		state.left = float(config.call_tell)
		z.facing = z.pos.direction_to(target.pos)
		return true
	return false
