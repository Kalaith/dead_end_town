extends "res://addons/hatchery/testing/capture_runner.gd"
## Capture tour for accessibility: the street fighting with the colour-safe palette, captions and reduced motion on,
## beside the same moment with them off. Run through tools/Capture.ps1 -Tour res://tools/capture_access.gd.
const Access = preload("res://scripts/presentation/access.gd")


func tour() -> void:
	var town: Node = await open_scene("res://scenes/town.tscn", 20)
	town.command("resume")
	var world: RefCounted = town.world
	world.player.hp = 25.0
	world.properties.home.gate_hp = float(world.balance.gate_health) * 0.4
	for z: Dictionary in world.zombies:
		if z.pos.distance_to(world.player.pos) < 900.0:
			z.pos = world.player.pos + Vector2(140, 60)
			z.hp = float(z.hp) * 0.5
			break
	await seconds(0.5)
	await shot("access_off")
	for key: String in ["colour_safe", "captions", "reduce_motion"]:
		town.hud.settings.set_value(key, true)
	town.hud.prefs.apply("colour_safe")
	town.hud.captions.add("gunshot", "Gunshot (draws zombies)", world.player.pos + Vector2(-400, 0), world.player.pos)
	town.hud.captions.add("strike", "A gate or barricade is being struck", world.player.pos + Vector2(10, 0), world.player.pos)
	await seconds(0.5)
	await shot("access_on")
