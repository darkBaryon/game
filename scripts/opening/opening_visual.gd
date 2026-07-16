extends Control

var phase: int = 0
var animation_time: float = 0.0


func set_phase(next_phase: int) -> void:
	phase = next_phase
	animation_time = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _draw() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("02050c"), true)
	_draw_stars(size)
	match phase:
		0:
			_draw_ark(size)
		1:
			_draw_corridor(size)
		2:
			_draw_robot(size)
		_:
			_draw_cryo_chamber(size)


func _draw_stars(size: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 10101
	for index in 120:
		var point := Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		var alpha := rng.randf_range(0.2, 0.75)
		draw_circle(point, rng.randf_range(0.4, 1.4), Color(0.7, 0.8, 1.0, alpha))


func _draw_ark(size: Vector2) -> void:
	var center := size * Vector2(0.53, 0.47)
	var drift := sin(animation_time * 0.25) * 4.0
	center.y += drift
	var hull := PackedVector2Array([
		center + Vector2(-360, -55),
		center + Vector2(245, -95),
		center + Vector2(355, -22),
		center + Vector2(355, 22),
		center + Vector2(245, 95),
		center + Vector2(-360, 55),
		center + Vector2(-410, 0),
	])
	draw_colored_polygon(hull, Color("0b1320"))
	draw_polyline(hull + PackedVector2Array([hull[0]]), Color("283b58"), 3.0, true)
	for index in 9:
		var window_position := center + Vector2(-210 + index * 54, -9)
		draw_rect(Rect2(window_position, Vector2(25, 5)), Color(0.26, 0.52, 0.75, 0.16), true)


func _draw_corridor(size: Vector2) -> void:
	var center := size * 0.5
	for index in 8:
		var inset := index * 45.0
		var alpha := 0.08 + index * 0.025
		draw_rect(Rect2(Vector2(inset, 65 + inset * 0.3), size - Vector2(inset * 2, 130 + inset * 0.6)), Color(0.18, 0.28, 0.42, alpha), false, 2.0)
	draw_line(Vector2(0, size.y), center + Vector2(-40, 40), Color("23344e"), 3)
	draw_line(Vector2(size.x, size.y), center + Vector2(40, 40), Color("23344e"), 3)
	var pulse := 0.35 + sin(animation_time * 3.0) * 0.15
	draw_circle(center + Vector2(0, -10), 12, Color(0.9, 0.2, 0.22, pulse))


func _draw_robot(size: Vector2) -> void:
	var center := size * Vector2(0.5, 0.48)
	var bob := sin(animation_time * 2.0) * 4.0
	center.y += bob
	draw_circle(center + Vector2(8, 18), 82, Color(0, 0, 0, 0.4))
	draw_circle(center, 76, Color("c8d5e9"))
	draw_circle(center, 64, Color("34445c"))
	draw_rect(Rect2(center + Vector2(-45, -22), Vector2(90, 45)), Color("0a1524"), true)
	draw_circle(center + Vector2(-22, -2), 8, Color("5db5ff"))
	draw_circle(center + Vector2(22, -2), 8, Color("5db5ff"))
	draw_line(center + Vector2(0, -75), center + Vector2(0, -108), Color("c8d5e9"), 5)
	draw_circle(center + Vector2(0, -116), 10, Color("ffbd55"))
	for index in 3:
		draw_line(center + Vector2(-58 + index * 32, 52), center + Vector2(-48 + index * 32, 74), Color("718198"), 4)


func _draw_cryo_chamber(size: Vector2) -> void:
	var center := size * Vector2(0.5, 0.5)
	var chamber := Rect2(center + Vector2(-185, -235), Vector2(370, 470))
	draw_style_box(_panel_style(Color("101b2c"), Color("4f6c94"), 18), chamber)
	var glass := chamber.grow(-28)
	draw_style_box(_panel_style(Color(0.08, 0.2, 0.3, 0.75), Color("6bbcf2"), 28), glass)
	draw_circle(center + Vector2(0, -72), 42, Color("9db3c9"))
	draw_rect(Rect2(center + Vector2(-60, -30), Vector2(120, 150)), Color("344b62"), true)
	var opening := clampf(animation_time / 1.5, 0.0, 1.0)
	draw_line(chamber.position + Vector2(185, 16), chamber.position + Vector2(185, 454), Color(0.5, 0.85, 1.0, 0.5 * (1.0 - opening)), 6)
	for index in 4:
		var mist_position := center + Vector2(sin(animation_time + index) * 105, 145 - index * 38)
		draw_circle(mist_position, 24 + index * 4, Color(0.5, 0.8, 1.0, 0.05))


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	return style
