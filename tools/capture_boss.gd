extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for the bridge: the baboon at its post with the roadblock, then the same spot with the baboon down.
## Run through tools/Capture.ps1 -Tour res://tools/capture_boss.gd.


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	town.command("resume")
	var post: Vector2 = Vector2(float(town.world.catalog.boss.post[0]), float(town.world.catalog.boss.post[1]))
	town.world.player.pos = post + Vector2(200, 20)
	await seconds(0.6)
	await shot("boss_baboon_post")
	for z: Dictionary in town.world.zombies:
		if z.id == town.world.catalog.boss.id:
			z.hp = 0.0
	await seconds(0.6)
	await shot("boss_exit_open")
