extends RefCounted
## Saves from before the yards were doubled hold fewer starting zombies, numbered in the old order. Renumber each lot's
## into the first slots of its new numbering; the rest of the residents are added afterwards from a fresh world.
const World = preload("res://scripts/sim/world.gd")


static func renumber(data: Dictionary, catalog: Dictionary) -> bool:
	if not data.get("zombies") is Array:
		return false
	var slots: Dictionary = {}
	for z: Dictionary in World.new(catalog).zombies:
		if _starting(z):
			if not slots.has(z.home):
				slots[z.home] = []
			slots[z.home].append(z.id)
	var used: Dictionary = {}
	var olds: Array = data.zombies.filter(func(z: Dictionary) -> bool: return _starting(z))
	olds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(str(a.id).substr(1)) < int(str(b.id).substr(1)))
	for z: Dictionary in olds:
		var list: Array = slots.get(z.home, [])
		var next: int = int(used.get(z.home, 0))
		if next >= list.size():
			return false
		used[z.home] = next + 1
		z.id = list[next]
	return true


static func _starting(z: Dictionary) -> bool:
	var id: String = str(z.get("id"))
	return not bool(z.get("raid", true)) and id.length() > 1 and id.begins_with("z") and id.substr(1).is_valid_int()
