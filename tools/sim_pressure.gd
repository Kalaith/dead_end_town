extends SceneTree
## Pressure over time with nobody steering, after the lots beside home are taken: raiders alive, waves and home damage each minute for 20 minutes, per area.
## Survivors still guard on their own orders. Run: Godot --headless --path . --script res://tools/sim_pressure.gd
const Catalog = preload("res://scripts/core/catalog.gd")
const World = preload("res://scripts/sim/world.gd")
const Pressure = preload("res://scripts/sim/pressure.gd")
const MINUTES: int = 20


func _init() -> void:
	for area: String in ["", "office", "industrial"]:
		var data: Dictionary = Catalog.read(area) if not area.is_empty() else Catalog.read()
		var world := World.new(data)
		world.player.hp = 100000.0
		# Pressure starts with the first yard taken, so take the lots beside home and then stand still.
		for id: String in world.definition("home").neighbors:
			world.properties[id].claimed = true
			world.properties[id].claimed_once = true
			world.properties[id].looted = true
			Pressure.claimed(world, id)
		var line: Array[String] = []
		for minute: int in range(1, MINUTES + 1):
			for i: int in range(int(60.0 / 0.1)):
				world.step(0.1)
				world.player.hp = 100000.0
			var raiders: int = 0
			for z: Dictionary in world.zombies:
				if z.raid and float(z.hp) > 0:
					raiders += 1
			if minute % 2 == 0:
				line.append("%d:%d/w%d" % [minute, raiders, int(world.pressure.wave)])
		print("%-11s raiders/wave by minute  %s  gate %d" % [data.area.id, " ".join(line), int(world.properties.home.gate_hp)])
	quit()
