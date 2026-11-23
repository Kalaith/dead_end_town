extends SceneTree
## Analytics for Hatchery Signals: data/analytics.json must read cleanly,
## every milestone the game can send (presentation/street_milestones.gd) must
## be a snake_case id, a new street must reach none of them and a finished
## one all of them, and the areas named must be in data/areas.json. One
## continuous world, so no run reports. Seconds; prints FAIL lines and exits
## 1 on a problem.
##
## With `-- --endpoint=http://127.0.0.1:8765/events` it also sends a real batch
## through the toolkit's signals_client.gd to that address (a local server,
## never the live portal) and expects HTTP 202.
##
## Run: godot --headless --path . --script res://tools/analytics_check.gd

const StreetMilestones = preload("res://scripts/presentation/street_milestones.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const CONFIG := "res://data/analytics.json"
const SignalsClient = preload("res://addons/hatchery/telemetry/signals_client.gd")
const SignalsConfig = preload("res://addons/hatchery/telemetry/signals_config.gd")
const AtomicFile = preload("res://addons/hatchery/storage/atomic_file.gd")
const LaunchArgs = preload("res://addons/hatchery/settings/launch_args.gd")

const SEND_TIMEOUT := 20.0
const IDS_FILE := "user://analytics_check_ids.json"
const QUEUE_FILE := "user://analytics_check_queue.json"

var _failures: int = 0
var _client: SignalsClient
var _waited: float = 0.0
var _replies: Array[int] = []
var _sent: int = 0
var _expected: int = 0


func _initialize() -> void:
	var errors: Array[String] = []
	SignalsConfig.read(CONFIG, errors)
	for error in errors:
		_check(false, "config: %s" % error)
	var snake := RegEx.create_from_string("^[a-z][a-z0-9]*(_[a-z0-9]+)*$")
	var names: Array[String] = StreetMilestones.all_names()
	_check_states(names)
	_check(names.size() >= 5, "only %d milestones" % names.size())
	for name in names:
		_check(snake.search(name) != null, "milestone '%s' is not snake_case" % name)
		_check(name.length() <= 64, "milestone '%s' is too long" % name)
	print("analytics_check: %d milestones" % names.size())
	var endpoint: String = LaunchArgs.value("endpoint")
	if endpoint.is_empty():
		_finish()
		return
	# The client's HTTPRequest needs the running tree, which starts after this.
	_send.call_deferred(endpoint, names)


func _process(delta: float) -> bool:
	if _client == null:
		return false
	_waited += delta
	if _sent >= _expected or _waited > SEND_TIMEOUT:
		_check(_sent == _expected, "only %d of %d events were answered" % [_sent, _expected])
		for code in _replies:
			_check(code == 202, "local endpoint answered %d, expected 202" % code)
		print("analytics_check: sent %d events in %d batches, HTTP %s" % [_sent, _replies.size(), str(_replies)])
		# Off first, so quitting does not queue (and save) a session end.
		_client.set_enabled(false)
		AtomicFile.remove_all(IDS_FILE)
		AtomicFile.remove_all(QUEUE_FILE)
		_finish()
	return false


func _send(endpoint: String, names: Array[String]) -> void:
	AtomicFile.remove_all(IDS_FILE)
	AtomicFile.remove_all(QUEUE_FILE)
	_client = SignalsClient.new()
	_client.ids_path = IDS_FILE
	_client.queue_path = QUEUE_FILE
	_client.endpoint_override = endpoint
	_client.batch_sent.connect(func(code: int, count: int) -> void:
		_replies.append(code)
		_sent += count)
	# session_started and every milestone.
	_expected = 1 + names.size()
	root.add_child(_client)
	_client.start(CONFIG, true, false, false)
	_check(_client.status != "", "client should stay off until enabled")
	_client.set_enabled(true)
	for name in names:
		_client.milestone_once(name)
	_client.game_completed()
	_expected += 1


## A new street reaches nothing; one with every lot held, a second survivor,
## the workshop done, the last area reached and the campaign over reaches
## every name; the areas exist.
func _check_states(names: Array[String]) -> void:
	var data: Dictionary = Catalog.read()
	_check(not data.is_empty(), "the catalog did not load")
	if data.is_empty():
		return
	var world: RefCounted = World.new(data)
	var reached: Array[String] = StreetMilestones.reached(world)
	_check(reached.is_empty(), "a new street reaches %s" % str(reached))
	for id: String in world.properties:
		world.properties[id].claimed = true
	world.survivors.append({})
	world.workshop.done = true
	world.area = StreetMilestones.AREAS[-1]
	world.campaign_ended = true
	reached = StreetMilestones.reached(world)
	for name in names:
		if name.begins_with("area_") and name != StreetMilestones.area_name(world.area):
			continue
		_check(reached.has(name), "a finished street never sends '%s'" % name)
	var areas: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/areas.json"))
	var ids: Array[String] = []
	for area in areas.areas:
		ids.append(str(area.id))
	for id in StreetMilestones.AREAS:
		_check(ids.has(id), "area '%s' is not in data/areas.json" % id)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		print("FAIL  ", message)


func _finish() -> void:
	print("analytics_check: %d failures" % _failures)
	quit(1 if _failures > 0 else 0)
