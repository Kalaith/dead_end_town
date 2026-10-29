extends SceneTree
## Content check: loads every data file and prints validation problems. Not a simulation.
## Run: Godot --headless --path . --script res://tools/check_catalog.gd


func _init() -> void:
	var catalog = load("res://scripts/core/catalog.gd")
	var total: int = 0
	for entry: Dictionary in catalog.registry().areas:
		var data: Dictionary = catalog.read(str(entry.id))
		var errors: Array = catalog.problems(data) if not data.is_empty() else ["could not load"]
		print("%s: catalog problems: %d" % [entry.id, errors.size()])
		for message: Variant in errors.slice(0, 20):
			print(" - ", message)
		total += errors.size()
	quit(1 if total > 0 else 0)
