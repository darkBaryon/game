class_name UIFactory
extends RefCounted


static func label(text: String, size: int = 18, color: Color = Color.WHITE) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node


static func button(text: String, accent: Color = Color("4f8cff")) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0, 48)
	node.add_theme_font_size_override("font_size", 17)
	node.add_theme_stylebox_override("normal", panel_style(accent.darkened(0.65), accent.darkened(0.2), 1, 10))
	node.add_theme_stylebox_override("hover", panel_style(accent.darkened(0.5), accent, 2, 10))
	node.add_theme_stylebox_override("pressed", panel_style(accent.darkened(0.35), accent.lightened(0.2), 2, 10))
	node.add_theme_stylebox_override("disabled", panel_style(Color("182034"), Color("30394e"), 1, 10))
	return node


static func panel_style(
	background: Color,
	border: Color = Color("2e4165"),
	border_width: int = 1,
	radius: int = 12
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


static func separator(color: Color = Color("273759")) -> HSeparator:
	var line := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_top = 1
	line.add_theme_stylebox_override("separator", style)
	return line
