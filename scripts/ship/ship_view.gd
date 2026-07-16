extends Control

signal launch_requested
signal reset_requested

const ShipVisual := preload("res://scripts/ship/ship_visual.gd")

var mission_report: String = ""
var resource_label: Label
var reactor_button: Button
var habitat_button: Button
var launch_button: Button
var status_label: Label
var visual: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_interface()
	GameState.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if GameState.changed.is_connected(_refresh):
		GameState.changed.disconnect(_refresh)


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("050b17")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 28)
	root_margin.add_theme_constant_override("margin_right", 28)
	root_margin.add_theme_constant_override("margin_top", 22)
	root_margin.add_theme_constant_override("margin_bottom", 22)
	add_child(root_margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	root_margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var title := UIFactory.label("星舰火种", 30, Color("eaf2ff"))
	title_box.add_child(title)
	var subtitle := UIFactory.label("方舟-01 · 航行日志 8472", 14, Color("8294b6"))
	title_box.add_child(subtitle)

	resource_label = UIFactory.label("", 18, Color("a9c7ff"))
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	resource_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resource_label.custom_minimum_size = Vector2(300, 0)
	header.add_child(resource_label)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	layout.add_child(content)

	var visual_panel := PanelContainer.new()
	visual_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("07101f"), Color("253754"), 1, 14))
	content.add_child(visual_panel)
	visual = ShipVisual.new()
	visual.custom_minimum_size = Vector2(760, 520)
	visual_panel.add_child(visual)

	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(355, 0)
	sidebar.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("0c1526"), Color("2a3c5c"), 1, 14))
	content.add_child(sidebar)

	var sidebar_layout := VBoxContainer.new()
	sidebar_layout.add_theme_constant_override("separation", 14)
	sidebar.add_child(sidebar_layout)

	sidebar_layout.add_child(UIFactory.label("A-01 / 舰桥助理", 20, Color("dce8ff")))
	status_label = UIFactory.label("", 16, Color("9fb0cc"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_layout.add_child(status_label)
	sidebar_layout.add_child(UIFactory.separator())

	reactor_button = UIFactory.button("重启聚变反应堆 · 8 废料", Color("ff9f43"))
	reactor_button.pressed.connect(_repair_reactor)
	sidebar_layout.add_child(reactor_button)

	habitat_button = UIFactory.button("修复生态舱 · 18 废料", Color("55d68b"))
	habitat_button.pressed.connect(_repair_habitat)
	sidebar_layout.add_child(habitat_button)

	launch_button = UIFactory.button("登陆废土 · 消耗 2 能源", Color("4f8cff"))
	launch_button.pressed.connect(func() -> void: launch_requested.emit())
	sidebar_layout.add_child(launch_button)

	var reset_button := UIFactory.button("重置原型进度", Color("68738a"))
	reset_button.custom_minimum_size.y = 38
	reset_button.pressed.connect(func() -> void: reset_requested.emit())
	sidebar_layout.add_child(reset_button)

	var footer := UIFactory.label("原型目标：修复反应堆 → 登陆废土 → 回收资源 → 点亮生态舱", 14, Color("6f829f"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(footer)


func _refresh() -> void:
	resource_label.text = "能源  %02d    废料  %02d    远征  %02d" % [GameState.energy, GameState.scrap, GameState.mission_count]
	visual.set_ship_state(GameState.reactor_repaired, GameState.habitat_repaired)

	reactor_button.disabled = GameState.reactor_repaired or GameState.scrap < 8
	reactor_button.text = "反应堆已上线" if GameState.reactor_repaired else "重启聚变反应堆 · 8 废料"

	habitat_button.disabled = GameState.habitat_repaired or not GameState.reactor_repaired or GameState.scrap < 18
	habitat_button.text = "生态舱已恢复" if GameState.habitat_repaired else "修复生态舱 · 18 废料"

	launch_button.disabled = not GameState.reactor_repaired or GameState.energy < 2
	if GameState.habitat_repaired:
		status_label.text = "舰长，第一层生态循环已经恢复。黑暗中出现了微弱但稳定的生命信号。\n\n原型循环完成。"
	elif not mission_report.is_empty():
		status_label.text = mission_report + "\n\n我们可以把这些材料投入生态舱。"
	elif GameState.reactor_repaired:
		status_label.text = "反应堆输出稳定在 12%。登陆艇已经获得最低启动能源。\n\n废土信标中检测到可回收合金。"
	else:
		status_label.text = "欢迎回来，舰长。\n\n很抱歉……我没有保护好我们的家。\n\n反应堆能源仅剩 3%，请先用备用材料重启核心。"


func _repair_reactor() -> void:
	if GameState.repair_reactor():
		mission_report = "A-01：核心温度上升。方舟-01 正在重新呼吸。"
		_refresh()


func _repair_habitat() -> void:
	if GameState.repair_habitat():
		mission_report = "A-01：检测到第一株幼苗的生命反应。"
		_refresh()
