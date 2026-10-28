extends RefCounted
## Zombie kinds are data (`data/zombies.json`). An actor without a `kind` is the default type.


static func kind(catalog: Dictionary, z: Dictionary) -> Dictionary:
	var types: Dictionary = catalog.zombies.types
	return types[z.get("kind", catalog.zombies.default)]


static func stat(catalog: Dictionary, z: Dictionary, key: String) -> float:
	return float(kind(catalog, z)[key])


static func type_name(catalog: Dictionary, type_id: String = "") -> String:
	return str(catalog.zombies.types[type_id if type_id != "" else catalog.zombies.default].name)


## Full health of this particular zombie, for meters and save checks.
static func full_health(catalog: Dictionary, z: Dictionary) -> float:
	return stat(catalog, z, "health")


## Starting health of a new zombie of the default kind or the named one.
static func health(catalog: Dictionary, type_id: String = "") -> float:
	return float(catalog.zombies.types[type_id if type_id != "" else catalog.zombies.default].health)


static func max_health(catalog: Dictionary) -> float:
	var best: float = 0.0
	for type_data: Dictionary in catalog.zombies.types.values():
		best = maxf(best, float(type_data.health))
	return best
