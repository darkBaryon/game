extends Control

signal completed

const OpeningVisual := preload("res://scripts/opening/opening_visual.gd")

const SLIDES: Array[Dictionary] = [
	{
		"eyebrow": "方舟计划 / 航行时间：8472 天",
		"title": "人类文明状态：未知",
		"body": "太阳熄灭后，方舟-01 一直漂浮在没有回音的宇宙中。",
	},
	{
		"eyebrow": "生命支持：3%",
		"title": "舰内城市已经沉睡",
		"body": "灯光熄灭，植物死亡。只有一台维护机器人还在执行最后任务。",
	},
	{
		"eyebrow": "A-01 / 维护日志",
		"title": "第 8472 次唤醒尝试",
		"body": "舰长生命信号确认。启动最后一次唤醒程序。",
	},
	{
		"eyebrow": "舰长权限恢复",
		"title": "欢迎回来，舰长。",
		"body": "很抱歉……我没有保护好我们的家。",
	},
]

var slide_index: int = 0
var visual: Control
var eyebrow_label: Label
var title_label: Label
var body_label: Label
var continue_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_interface()
	_show_slide(0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			advance()
			get_viewport().set_input_as_handled()


func _build_interface() -> void:
	visual = OpeningVisual.new()
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)

	var vignette := ColorRect.new()
	vignette.color = Color(0.01, 0.02, 0.04, 0.34)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var text_panel := PanelContainer.new()
	text_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	text_panel.offset_left = 48
	text_panel.offset_right = -48
	text_panel.offset_top = -220
	text_panel.offset_bottom = -34
	text_panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color(0.025, 0.05, 0.09, 0.95), Color("2c466c"), 1, 14))
	add_child(text_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	text_panel.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 8)
	row.add_child(copy)

	eyebrow_label = UIFactory.label("", 14, Color("6f9ad2"))
	copy.add_child(eyebrow_label)
	title_label = UIFactory.label("", 28, Color("edf5ff"))
	copy.add_child(title_label)
	body_label = UIFactory.label("", 17, Color("aabbd4"))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(body_label)

	continue_button = UIFactory.button("继续  1 / 4", Color("4f8cff"))
	continue_button.custom_minimum_size = Vector2(180, 54)
	continue_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(advance)
	row.add_child(continue_button)

	var skip_button := Button.new()
	skip_button.text = "跳过序章"
	skip_button.position = Vector2(1140, 24)
	skip_button.size = Vector2(110, 38)
	skip_button.add_theme_color_override("font_color", Color("7186a6"))
	skip_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	skip_button.add_theme_stylebox_override("hover", UIFactory.panel_style(Color(0.08, 0.12, 0.2, 0.8), Color("334867"), 1, 8))
	skip_button.pressed.connect(_complete)
	add_child(skip_button)


func advance() -> void:
	AudioDirector.play_ui()
	if slide_index >= SLIDES.size() - 1:
		_complete()
		return
	_show_slide(slide_index + 1)


func _show_slide(index: int) -> void:
	slide_index = index
	var slide: Dictionary = SLIDES[slide_index]
	eyebrow_label.text = str(slide["eyebrow"])
	title_label.text = str(slide["title"])
	body_label.text = str(slide["body"])
	continue_button.text = "进入舰桥" if slide_index == SLIDES.size() - 1 else "继续  %d / %d" % [slide_index + 1, SLIDES.size()]
	visual.set_phase(slide_index)


func _complete() -> void:
	AudioDirector.play_repair()
	completed.emit()
