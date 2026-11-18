extends Control
const Access = preload("res://scripts/presentation/access.gd")
## Health is a shape and a bar. Ammunition earns a number only after discovery.
var health: float = 1.0
var armed: bool = false
var bullets: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = "Health · bullets"


func refresh(world: RefCounted) -> void:
	health = clampf(float(world.player.hp) / float(world.balance.player_health), 0.0, 1.0)
	armed = world.firearms.owned
	bullets = int(world.firearms.bullets)
	tooltip_text = "Health %d" % int(world.player.hp)
	if armed:
		tooltip_text += " · %d bullets" % bullets
	queue_redraw()


func _draw() -> void:
	var ink := Color("142426")
	var cream := Color("e7dfc9")
	var accent: Color = Access.health(health)
	draw_style_box(_backing(ink), Rect2(0, 0, 196 if armed else 132, 36))
	draw_rect(Rect2(12, 15, 16, 6), accent)
	draw_rect(Rect2(17, 10, 6, 16), accent)
	draw_rect(Rect2(38, 14, 78, 8), Color("3a534c"))
	draw_rect(Rect2(38, 14, 78 * health, 8), accent)
	if armed:
		draw_rect(Rect2(134, 14, 6, 11), cream)
		draw_colored_polygon(PackedVector2Array([Vector2(134, 14), Vector2(137, 9), Vector2(140, 14)]), cream)
		draw_string(ThemeDB.fallback_font, Vector2(150, 25), str(bullets), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, cream)


func _backing(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	return box
