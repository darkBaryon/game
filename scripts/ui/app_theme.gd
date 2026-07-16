extends Node

const APP_FONT: FontFile = preload("res://assets/fonts/NotoSansSC-GB2312.ttf")

var theme: Theme


func _ready() -> void:
	theme = Theme.new()
	theme.default_font = APP_FONT
	theme.default_font_size = 18
	get_tree().root.theme = theme
