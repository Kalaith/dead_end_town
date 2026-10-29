extends SceneTree
## Content check: loads every data file and prints validation problems. Not a simulation.
## Run: Godot --headless --path . --script res://tools/check_catalog.gd


func _init() -> void:
	var catalog = load("res://scripts/core/catalog.gd")
	var errors: Array = catalog.problems(catalog.read())
	print("catalog problems: ", errors.size())
	for message: Variant in errors.slice(0, 20):
		print(" - ", message)
	quit(1 if not errors.is_empty() else 0)
