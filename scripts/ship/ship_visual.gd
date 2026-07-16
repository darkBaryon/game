extends Control

var reactor_active: bool = false
var habitat_active: bool = false


func set_ship_state(reactor: bool, habitat: bool) -> void:
	reactor_active = reactor
	habitat_active = habitat
	queue_redraw()


func _draw() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("07101f"), true)
	_draw_stars(size)
	_draw_grid(size)

	var center := size * Vector2(0.52, 0.52)
	var hull := PackedVector2Array([
		center + Vector2(-285, -120),
		center + Vector2(205, -155),
		center + Vector2(295, -45),
		center + Vector2(295, 45),
		center + Vector2(205, 155),
		center + Vector2(-285, 120),
		center + Vector2(-325, 0),
	])
	draw_colored_polygon(hull, Color("101b2c"))
	draw_polyline(hull + PackedVector2Array([hull[0]]), Color("405171"), 3.0, true)

	_draw_room(center + Vector2(-150, -55), Vector2(175, 110), "REACTOR", reactor_active, Color("ff9f43"))
	_draw_room(center + Vector2(65, -55), Vector2(175, 110), "ECO LAB", habitat_active, Color("55d68b"))
	_draw_room(center + Vector2(-40, 70), Vector2(190, 62), "CRYO DECK", false, Color("6da8ff"))

	# A-01 maintenance robot.
	var robot_pos := center + Vector2(-35, 18)
	draw_circle(robot_pos, 14, Color("d7e4ff"))
	draw_circle(robot_pos + Vector2(-5, -2), 2.5, Color("4f8cff"))
	draw_circle(robot_pos + Vector2(5, -2), 2.5, Color("4f8cff"))
	draw_line(robot_pos + Vector2(0, -14), robot_pos + Vector2(0, -24), Color("d7e4ff"), 2)
	draw_circle(robot_pos + Vector2(0, -26), 3, Color("ffca66"))


func _draw_stars(size: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8472
	for index in 90:
		var point := Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		var brightness := rng.randf_range(0.2, 0.8)
		draw_circle(point, rng.randf_range(0.5, 1.6), Color(brightness, brightness, brightness + 0.1, 0.8))


func _draw_grid(size: Vector2) -> void:
	for x in range(0, int(size.x), 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.12, 0.2, 0.34, 0.16), 1)
	for y in range(0, int(size.y), 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.12, 0.2, 0.34, 0.16), 1)


func _draw_room(position: Vector2, room_size: Vector2, title: String, active: bool, accent: Color) -> void:
	var rect := Rect2(position, room_size)
	var fill := accent.darkened(0.75) if active else Color("151c29")
	var border := accent if active else Color("384256")
	if active:
		draw_rect(rect.grow(7), Color(accent, 0.08), true)
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 2.0)
	var status := "ONLINE" if active else "OFFLINE"
	var status_color := accent if active else Color("778196")
	draw_string(ThemeDB.fallback_font, position + Vector2(14, 28), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("dce7ff"))
	draw_string(ThemeDB.fallback_font, position + Vector2(14, 54), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, status_color)
