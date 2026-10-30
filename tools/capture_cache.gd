extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for a supply cache: the market stalls before and after searching. Run through
## tools/Capture.ps1 -Tour res://tools/capture_cache.gd.


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	town.command("resume")
	for z: Dictionary in town.world.zombies:
		z.hp = 0.0
	var at: Vector2 = Vector2(float(town.world.catalog.caches[0].pos[0]), float(town.world.catalog.caches[0].pos[1]))
	town.world.player.pos = at + Vector2(-70, 20)
	await seconds(0.6)
	town.world.player.pos = at + Vector2(-30, 10)
	await seconds(0.4)
	await shot("cache_market")
	town.world.interact()
	await seconds(0.4)
	await shot("cache_market_searched")
