extends RefCounted
## Advisory only: describes how prepared the community is for leaving. It never blocks anything.
const Roadworks = preload("res://scripts/sim/roadworks.gd")


static func summary(world: RefCounted) -> String:
	var lines: PackedStringArray = []
	lines.append("Food %d (a shared meal costs %d)" % [world.food, 1 + world.survivors.size()])
	lines.append("Medicine %d" % world.medicine)
	lines.append("Bullets %d" % int(world.firearms.bullets) if world.firearms.owned else "No firearm yet")
	lines.append(_perimeter(world))
	lines.append(_defenders(world))
	return "\n".join(lines)


static func _perimeter(world: RefCounted) -> String:
	var standing: int = 0
	var weak: int = 0
	for d: Dictionary in world.catalog.barricades:
		var state: Dictionary = world.roadworks[d.id]
		if Roadworks.active(state):
			standing += 1
			if float(state.hp) < float(world.balance.barricade_health) * 0.5:
				weak += 1
	return "Barricades %d of %d standing%s" % [standing, world.catalog.barricades.size(), ", %d damaged" % weak if weak > 0 else ""]


static func _defenders(world: RefCounted) -> String:
	var able: int = 0
	for a: Dictionary in world.survivors:
		if float(a.hp) > 0:
			able += 1
	return "Defenders %d of %d survivors able, player %s" % [able, world.survivors.size(), "down" if float(world.player.hp) <= 0 else "fit"]
