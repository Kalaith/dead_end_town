extends Node
## Plays the street's sounds by watching the world each frame; the simulation knows nothing of audio. Gunshots,
## swings and hits, zombie groans that fall off with distance, gates and barricades being struck, work and finished
## projects, the van's engine, a chime for a new tip, and each area's ambient bed. `heard` reports the cues that
## carry information (for captions).
const CueBank = preload("res://addons/hatchery/audio/cue_bank.gd")
const Ambience = preload("res://addons/hatchery/audio/ambience.gd")
const Levels = preload("res://addons/hatchery/audio/levels.gd")
const Sounds = preload("res://scripts/presentation/street_sounds.gd")
const WorkOrders = preload("res://scripts/sim/work_orders.gd")
const GROAN_RANGE: float = 700.0
const GROAN_SECONDS: float = 2.6
const ENGINE_SECONDS: float = 0.3
## A cue with a caption: name, what it means, and where (so a caption can say which side).
signal heard(cue: String, caption: String, pos: Vector2)
var cues: Node
var ambience: Node
var _world: RefCounted
var _last: Dictionary = {}
var _groan_left: float = 0.0
var _engine_left: float = 0.0


func _ready() -> void:
	Levels.ensure_bus("Effects")
	Levels.ensure_bus("Ambience")
	cues = CueBank.new()
	cues.bus = &"Effects"
	add_child(cues)
	Sounds.register(cues)
	ambience = Ambience.new()
	ambience.bus = &"Ambience"
	add_child(ambience)


## Called every frame with the world being shown; `paused` keeps the bed but plays no new cues.
func listen(world: RefCounted, paused: bool, dt: float) -> void:
	if world != _world:
		_world = world
		_last = _read(world)
		ambience.play_bed(str(world.area), Sounds.bed(str(world.area)))
		return
	var now: Dictionary = _read(world)
	if not paused:
		_compare(world, now, dt)
	_last = now


func _read(world: RefCounted) -> Dictionary:
	var zombie_hp: float = 0.0
	for z: Dictionary in world.zombies:
		zombie_hp += maxf(0.0, float(z.hp))
	var defences: float = 0.0
	for state: Dictionary in world.properties.values():
		defences += float(state.gate_hp)
	for state: Dictionary in world.roadworks.values():
		defences += float(state.hp)
	var work: float = 0.0
	var finished: int = 0
	for order: Dictionary in world.orders.sites.values():
		if WorkOrders.pending(order):
			work += float(order.work_done)
		elif order.phase == "completed":
			finished += 1
	return {"shot": float(world.shot.left), "swing": float(world.player.swing), "zombie_hp": zombie_hp, "defences": defences, "work": work, "finished": finished, "tip": str(world.tips.current)}


func _compare(world: RefCounted, now: Dictionary, dt: float) -> void:
	var at: Vector2 = world.player.pos
	if float(now.shot) > float(_last.shot):
		cues.cue("gunshot")
		heard.emit("gunshot", "Gunshot (draws zombies)", at)
	if float(now.swing) > float(_last.swing):
		cues.cue("swing", randf_range(0.9, 1.1))
	if float(now.zombie_hp) < float(_last.zombie_hp) - 0.5:
		cues.cue("hit", randf_range(0.85, 1.15))
	if float(now.defences) < float(_last.defences) - 0.5:
		cues.cue("strike", randf_range(0.9, 1.05))
		heard.emit("strike", "A gate or barricade is being struck", at)
	if float(now.work) > float(_last.work):
		cues.cue("work", randf_range(0.95, 1.1))
	if int(now.finished) > int(_last.finished):
		cues.cue("built")
	if str(now.tip) != str(_last.tip) and not str(now.tip).is_empty():
		cues.cue("tip")
	_groan(world, dt)
	_engine(world, dt)


## The nearest living zombie groans now and then, quieter with distance.
func _groan(world: RefCounted, dt: float) -> void:
	_groan_left -= dt
	if _groan_left > 0.0:
		return
	_groan_left = GROAN_SECONDS * randf_range(0.7, 1.3)
	var nearest: Dictionary = {}
	var distance: float = GROAN_RANGE
	for z: Dictionary in world.zombies:
		var d: float = world.player.pos.distance_to(z.pos)
		if float(z.hp) > 0 and d < distance:
			distance = d
			nearest = z
	if nearest.is_empty():
		return
	cues.cue("groan", randf_range(0.85, 1.1), -24.0 * distance / GROAN_RANGE)
	heard.emit("groan", "Zombie groaning nearby", nearest.pos)


func _engine(world: RefCounted, dt: float) -> void:
	if not bool(world.vehicle.get("driving", false)):
		return
	_engine_left -= dt
	if _engine_left > 0.0:
		return
	_engine_left = ENGINE_SECONDS
	var speed: float = absf(float(world.vehicle.speed)) / maxf(1.0, float(world.catalog.vehicle.forward))
	cues.cue("engine", 0.8 + speed * 0.6)
	heard.emit("engine", "Van engine (draws zombies)", world.player.pos)
