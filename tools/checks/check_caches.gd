extends SceneTree
## Open-air supply caches: reachable, searched once, refused with zombies close, saved, and added to older saves.
## Run: Godot --headless --path . --script res://tools/checks/check_caches.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const SaveState = preload("res://scripts/core/save_state.gd")
const World = preload("res://scripts/sim/world.gd")
const Routes = preload("res://scripts/sim/routes.gd")
var failures: int = 0


func _init() -> void:
	for area: String in ["", "office", "industrial"]:
		var data: Dictionary = Catalog.read(area) if not area.is_empty() else Catalog.read()
		var world := World.new(data)
		var cache: Dictionary = data.caches[0]
		var at: Vector2 = Routes.point(cache.pos)
		var name: String = str(data.area.id)
		_expect("%s: the cache can be stood beside" % name, world.routes.walkable(at))
		for z: Dictionary in world.zombies:
			z.hp = 0.0
		world.player.hp = 100.0
		world.player.pos = at + Vector2(20, 0)
		_expect("%s: it offers a search" % name, world.context().begins_with("E Search"))
		var stock: Array[int] = [world.materials, world.food, world.medicine]
		var crowd: Dictionary = World.actor("cache_z", "Shambler", at + Vector2(80, 0), 60.0)
		crowd.home = "home"
		crowd.raid = false
		crowd.cooldown = 100.0
		world.zombies.append(crowd)
		world.interact()
		_expect("%s: a zombie close by stops the search" % name, world.materials == stock[0] and world.caches_taken.is_empty())
		world.zombies.erase(crowd)
		world.interact()
		_expect("%s: searching pays out" % name, world.materials == stock[0] + int(cache.materials) and world.food == stock[1] + int(cache.food) and world.medicine == stock[2] + int(cache.medicine))
		world.interact()
		_expect("%s: a second search pays nothing" % name, world.materials == stock[0] + int(cache.materials))
		var saves := SaveState.new(data, "user://check_caches.json")
		var raw: Dictionary = JSON.parse_string(JSON.stringify(saves.snapshot(world)))
		var loaded: RefCounted = saves.restore(raw)
		_expect("%s: what was taken survives a save" % name, loaded != null and loaded.caches_taken == [cache.id])
		raw.schema_version = 43
		raw.erase("caches_taken")
		var old: RefCounted = saves.restore(raw)
		_expect("%s: a schema 43 save has taken nothing" % name, old != null and old.caches_taken.is_empty())
		raw.schema_version = 44
		raw.caches_taken = ["nowhere"]
		_expect("%s: an unknown cache id is rejected" % name, saves.restore(raw) == null)
	print("%d failures" % failures)
	quit(1 if failures > 0 else 0)


func _expect(label: String, ok: bool) -> void:
	print(("pass  " if ok else "FAIL  ") + label)
	if not ok:
		failures += 1
