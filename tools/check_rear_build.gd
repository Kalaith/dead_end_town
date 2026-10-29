extends SceneTree
## Build check: a rear gate between the island rows can be approved and built through the normal interaction and work,
## and then opens. Run: Godot --headless --path . --script res://tools/check_rear_build.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var failures: int = 0


func _init() -> void:
	var data: Dictionary = Catalog.read()
	var world := World.new(data)
	var d: Dictionary = {}
	for entry: Dictionary in data.passages:
		if entry.id == "library_house_d":
			d = entry
	for id: String in d.requires:
		world.properties[id].claimed = true
		world.properties[id].claimed_once = true
		world.properties[id].looted = true
	world.materials = 100
	world.player.hp = 100.0
	world.player.pos = Routes.point(d.sites[0])
	_expect("the context offers the passage", world.context().contains("Passage") or world.context().contains("passage"))
	world.interact()
	_expect("interacting approves it", world.passages[d.id].started)
	world.working = true
	for i: int in range(int(120.0 / 0.05)):
		world.player.pos = Routes.point(d.sites[0])
		world.step(0.05)
		if world.passages[d.id].done:
			break
	world.working = false
	_expect("working on it finishes the build", world.passages[d.id].done)
	_expect("it starts shut and opens with E", not world.passages[d.id].open)
	world.interact()
	_expect("E opens the finished gate", world.passages[d.id].open)
	quit(failures)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
