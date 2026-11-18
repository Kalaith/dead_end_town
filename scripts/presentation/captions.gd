extends VBoxContainer
## Captions for the sounds that carry information (gunshots and the engine draw zombies, a struck gate, a groan
## nearby), bottom right above the radio line, each with which side it came from. Shown only with Captions on.
const Access = preload("res://scripts/presentation/access.gd")
const SECONDS: float = 3.0
const LINES: int = 3
## A cue captioned again within this long only refreshes its line.
const REPEAT: float = 2.5
var kit: RefCounted
var _lines: Array[Dictionary] = []


func setup(ui_kit: RefCounted) -> void:
	kit = ui_kit
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_END
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -520.0
	offset_right = -20.0
	offset_top = -220.0
	offset_bottom = -96.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN


## `from` is where the sound was, `listener` where the player stands.
func add(cue: String, caption: String, from: Vector2, listener: Vector2) -> void:
	if not Access.captions:
		return
	var side: String = "nearby" if absf(from.x - listener.x) < 120.0 else ("left" if from.x < listener.x else "right")
	var text: String = "[%s] %s" % [side, caption]
	for line: Dictionary in _lines:
		if line.cue == cue and float(line.age) < REPEAT:
			line.text = text
			line.age = 0.0
			_redraw()
			return
	_lines.append({"cue": cue, "text": text, "age": 0.0})
	while _lines.size() > LINES:
		_lines.pop_front()
	_redraw()


func step(dt: float) -> void:
	var before: int = _lines.size()
	for line: Dictionary in _lines:
		line.age = float(line.age) + dt
	_lines = _lines.filter(func(line: Dictionary) -> bool: return float(line.age) < SECONDS)
	if _lines.size() != before:
		_redraw()
	visible = Access.captions and not _lines.is_empty()


func lines() -> Array[String]:
	var result: Array[String] = []
	for line: Dictionary in _lines:
		result.append(str(line.text))
	return result


func _redraw() -> void:
	for child: Node in get_children():
		child.queue_free()
	for line: Dictionary in _lines:
		var label: Label = kit.label(str(line.text), 16, Color("f5e6c2"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.size_flags_horizontal = Control.SIZE_SHRINK_END
		var backing := StyleBoxFlat.new()
		backing.bg_color = Color(0.08, 0.14, 0.15, 0.88)
		backing.set_content_margin_all(6)
		backing.set_corner_radius_all(4)
		label.add_theme_stylebox_override("normal", backing)
		label.add_theme_color_override("font_shadow_color", Color("142426"))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(label)
