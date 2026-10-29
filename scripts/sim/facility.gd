extends RefCounted
## Facilities are data: each lot declares what it holds (`facility` in its JSON) and code asks for a facility by kind
## instead of by lot id. An area without a given facility reads as one that is never claimed or looted.
const KINDS: Array[String] = ["home", "garden", "library", "garage", "clinic", "greenhouse", "munitions", "residence", "hardware"]
const HOUSE: String = "house"


## The lot holding this facility, or "" when the area has none.
static func id(catalog: Dictionary, kind: String) -> String:
	for p: Dictionary in catalog.properties:
		if p.facility == kind:
			return str(p.id)
	return ""


static func has(catalog: Dictionary, kind: String) -> bool:
	return not id(catalog, kind).is_empty()


static func kind_of(catalog: Dictionary, property_id: String) -> String:
	for p: Dictionary in catalog.properties:
		if p.id == property_id:
			return str(p.facility)
	return ""


static func definition(catalog: Dictionary, kind: String) -> Dictionary:
	for p: Dictionary in catalog.properties:
		if p.facility == kind:
			return p
	return {}


## Live state of the facility's lot. For a missing facility this is a fresh inert record; writing to it does nothing.
static func state(world: RefCounted, kind: String) -> Dictionary:
	var lot: String = id(world.catalog, kind)
	return world.properties[lot] if not lot.is_empty() else inert()


## The same lookup on a saved or decoded record (`data.properties`).
static func saved(data: Dictionary, catalog: Dictionary, kind: String) -> Dictionary:
	var lot: String = id(catalog, kind)
	return data.properties[lot] if not lot.is_empty() else inert()


static func inert() -> Dictionary:
	return {"claimed_once": false, "claimed": false, "looted": false, "open": false, "occupation": 0.0, "gate_hp": 0.0}
