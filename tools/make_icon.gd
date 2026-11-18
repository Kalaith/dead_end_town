extends SceneTree
## Draws the game's icon (res://icon.png, 256x256) procedurally in the greybox palette: a lit house behind a fence
## and gate, with a dead-end bar across the road in front. Rerun to regenerate. Run:
## Godot --headless --path . --script res://tools/make_icon.gd
const SIZE: int = 256


func _init() -> void:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_round_rect(image, Rect2i(8, 8, 240, 240), 36, Color("142426"))
	_fill(image, Rect2i(8, 170, 240, 50), Color("2b3333"))
	for x: int in range(20, 240, 36):
		_fill(image, Rect2i(x, 193, 20, 4), Color("ada47b"))
	# The house: roof, walls, two lit windows and a door.
	for row: int in range(40):
		_fill(image, Rect2i(128 - 6 - row * 17 / 10, 48 + row, 12 + row * 17 / 5, 1), Color("3f5b5c"))
	_fill(image, Rect2i(70, 88, 116, 62), Color("8e8a72"))
	_fill(image, Rect2i(82, 102, 24, 20), Color("e6c46a"))
	_fill(image, Rect2i(150, 102, 24, 20), Color("e6c46a"))
	_fill(image, Rect2i(117, 114, 22, 36), Color("263536"))
	# The fence with its gate, and posts.
	_fill(image, Rect2i(30, 152, 196, 6), Color("c9a777"))
	for x: int in range(30, 228, 28):
		_fill(image, Rect2i(x, 144, 6, 22), Color("c9a777"))
	_fill(image, Rect2i(108, 146, 40, 14), Color("9dceb3"))
	# The dead-end bar across the road: white with rust stripes.
	_fill(image, Rect2i(40, 206, 176, 16), Color("e7dfc9"))
	for x: int in range(48, 210, 32):
		_fill(image, Rect2i(x, 206, 14, 16), Color("d88c63"))
	_fill(image, Rect2i(44, 222, 8, 18), Color("575e4d"))
	_fill(image, Rect2i(204, 222, 8, 18), Color("575e4d"))
	var error: Error = image.save_png("res://icon.png")
	print("icon.png written" if error == OK else "icon.png failed: %d" % error)
	quit(0 if error == OK else 1)


func _fill(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect.intersection(Rect2i(0, 0, SIZE, SIZE)), color)


func _round_rect(image: Image, rect: Rect2i, radius: int, color: Color) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var cx: int = clampi(x, rect.position.x + radius, rect.end.x - radius - 1)
			var cy: int = clampi(y, rect.position.y + radius, rect.end.y - radius - 1)
			if Vector2(x - cx, y - cy).length() <= radius:
				image.set_pixel(x, y, color)
