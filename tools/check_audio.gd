extends SceneTree
## Street audio: each moment the world shows plays its cue, a paused game plays none, captions are raised for the
## sounds that carry information, and every area has a bed. Headless, so cues are counted, not heard. Run:
## Godot --headless --path . --script res://tools/check_audio.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const StreetAudio = preload("res://scripts/presentation/street_audio.gd")
var failures: int = 0
var captions: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var audio: Node = StreetAudio.new()
	root.add_child(audio)
	audio.heard.connect(func(cue: String, _caption: String, _pos: Vector2) -> void: captions.append(cue))
	var data: Dictionary = Catalog.read()
	var world := World.new(data)
	audio.listen(world, false, 0.1)
	_expect("the suburb bed plays", audio.ambience.current == "suburb")
	world.shot.left = 0.2
	world.player.swing = 0.3
	world.zombies[0].hp = float(world.zombies[0].hp) - 10.0
	world.properties.home.gate_hp = float(world.properties.home.gate_hp) - 5.0
	world.tips.current = "swing"
	audio.listen(world, false, 0.1)
	for cue: String in ["gunshot", "swing", "hit", "strike", "tip"]:
		_expect("%s plays" % cue, int(audio.cues.played.get(cue, 0)) == 1)
	_expect("gunshots and strikes are captioned", "gunshot" in captions and "strike" in captions)
	world.shot.left = 0.0
	audio.listen(world, true, 0.1)
	world.shot.left = 0.3
	audio.listen(world, true, 0.1)
	_expect("a paused game plays nothing new", int(audio.cues.played.get("gunshot", 0)) == 1)
	for i: int in range(40):
		audio.listen(world, false, 0.1)
	_expect("a nearby zombie groans", int(audio.cues.played.get("groan", 0)) >= 1 and "groan" in captions)
	for id: String in ["office", "industrial"]:
		audio.listen(World.new(Catalog.read(id)), false, 0.1)
		_expect("the %s has its own bed" % id, audio.ambience.current == id)
	audio.queue_free()
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
