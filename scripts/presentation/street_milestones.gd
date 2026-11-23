extends RefCounted
## The once-per-install milestones sent to Hatchery Signals (the toolkit's
## telemetry/signals_client.gd, started in town.gd), read from the world.
## Pure: the same world gives the same names. Each answers a design
## question: do players secure a lot, rescue someone, restore the workshop,
## hold more of the street, reach the next area, finish the campaign?

## Lots held at once in the current area that are worth a milestone.
const HELD_COUNTS: Array[int] = [3, 6, 10, 16]
## Areas in data/areas.json past the first.
const AREAS: Array[String] = ["office", "industrial"]


static func reached(world: RefCounted) -> Array[String]:
	var names: Array[String] = []
	var held: int = 0
	for id: String in world.properties:
		if bool(world.properties[id].claimed):
			held += 1
	if held >= 2:
		names.append("first_property_secured")
	for count in HELD_COUNTS:
		if held >= count:
			names.append(held_name(count))
	if world.survivors.size() >= 2:
		names.append("first_survivor_rescued")
	if bool(world.workshop.get("done", false)):
		names.append("first_workshop")
	if AREAS.has(str(world.area)):
		names.append(area_name(str(world.area)))
	if bool(world.campaign_ended):
		names.append("street_held")
	return names


static func held_name(count: int) -> String:
	return "properties_%d_held" % count


static func area_name(id: String) -> String:
	return "area_%s_reached" % id


## Every name this game can send, for tools/analytics_check.gd.
static func all_names() -> Array[String]:
	var names: Array[String] = ["first_property_secured", "first_survivor_rescued", "first_workshop", "street_held"]
	for count in HELD_COUNTS:
		names.append(held_name(count))
	for id in AREAS:
		names.append(area_name(id))
	return names
