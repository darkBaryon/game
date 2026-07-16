extends Node2D

signal mission_finished(recovered_scrap: int, success: bool, reason: String)

const Player := preload("res://scripts/expedition/player.gd")
const Enemy := preload("res://scripts/expedition/enemy.gd")
const Pickup := preload("res://scripts/expedition/scrap_pickup.gd")

const MISSION_DURATION := 55.0
const BOSS_TIME := 32.0
const UPGRADE_THRESHOLDS: Array[int] = [4, 10]
const UPGRADES: Array[Dictionary] = [
	{
		"id": &"overcharge",
		"title": "等离子过载",
		"description": "自动武器伤害 +40%",
		"accent": Color("ff7b7b"),
	},
	{
		"id": &"rapid_fire",
		"title": "脉冲供能",
		"description": "攻击间隔缩短 24%",
		"accent": Color("ffbd55"),
	},
	{
		"id": &"nanoshield",
		"title": "纳米护盾",
		"description": "生命上限 +35，并恢复生命",
		"accent": Color("65d99a"),
	},
]

var player: ExpeditionPlayer
var elapsed: float = 0.0
var spawn_cooldown: float = 0.3
var recovered_scrap: int = 0
var kills: int = 0
var boss_spawned: bool = false
var boss_defeated: bool = false
var mission_ended: bool = false
var next_upgrade_index: int = 0

var health_bar: ProgressBar
var scrap_label: Label
var time_label: Label
var objective_label: Label
var extract_button: Button
var message_label: Label
var upgrade_layer: CanvasLayer
var upgrade_overlay: Control


func _ready() -> void:
	_build_world()
	_build_hud()
	for index in 5:
		_spawn_enemy(false)
	queue_redraw()


func _process(delta: float) -> void:
	if mission_ended:
		return
	elapsed += delta
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		_spawn_enemy(false)
		spawn_cooldown = maxf(1.6 - elapsed * 0.012, 0.75)
	if elapsed >= BOSS_TIME and not boss_spawned:
		boss_spawned = true
		_spawn_enemy(true)
		message_label.text = "警告：大型守卫信号正在接近"
	if elapsed >= MISSION_DURATION and not boss_defeated:
		_finish(false, "登陆艇能源耗尽。")
	_update_hud()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("090d18"), true)
	for x in range(0, 1281, 64):
		draw_line(Vector2(x, 72), Vector2(x, 720), Color(0.13, 0.2, 0.3, 0.28), 1)
	for y in range(80, 721, 64):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.13, 0.2, 0.3, 0.28), 1)

	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	for index in 38:
		var position := Vector2(rng.randf_range(20, 1260), rng.randf_range(100, 700))
		var radius := rng.randf_range(5, 19)
		draw_circle(position, radius, Color(0.18, 0.2, 0.24, 0.48))
		draw_arc(position, radius, 0.2, 3.4, 12, Color(0.25, 0.29, 0.34, 0.45), 2)


func _build_world() -> void:
	player = Player.new()
	player.position = Vector2(640, 390)
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	add_child(player)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(20, 16)
	top_panel.size = Vector2(1240, 64)
	top_panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color(0.025, 0.055, 0.1, 0.94), Color("294369"), 1, 10))
	layer.add_child(top_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	top_panel.add_child(row)
	row.add_child(UIFactory.label("废土回收区 K-17", 18, Color("dce9ff")))
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(250, 25)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", UIFactory.panel_style(Color("24192a"), Color("4d3559"), 1, 6))
	health_bar.add_theme_stylebox_override("fill", UIFactory.panel_style(Color("bd4b62"), Color("ff7b8f"), 0, 6))
	row.add_child(health_bar)
	row.add_child(UIFactory.label("生命", 14, Color("d99aa8")))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	scrap_label = UIFactory.label("废料 00", 18, Color("69d7ff"))
	row.add_child(scrap_label)
	time_label = UIFactory.label("00:55", 18, Color("ffcf70"))
	time_label.custom_minimum_size.x = 75
	row.add_child(time_label)

	var objective_panel := PanelContainer.new()
	objective_panel.position = Vector2(20, 96)
	objective_panel.size = Vector2(330, 104)
	objective_panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color(0.025, 0.055, 0.1, 0.88), Color("294369"), 1, 10))
	layer.add_child(objective_panel)
	var objective_box := VBoxContainer.new()
	objective_box.add_theme_constant_override("separation", 4)
	objective_panel.add_child(objective_box)
	objective_box.add_child(UIFactory.label("任务目标", 14, Color("7f96b9")))
	objective_label = UIFactory.label("收集废料，等待守卫出现", 16, Color("e2ebff"))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_box.add_child(objective_label)

	message_label = UIFactory.label("WASD / 方向键移动 · 武器自动锁定", 15, Color("a4b5ce"))
	message_label.position = Vector2(400, 92)
	message_label.size = Vector2(480, 40)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(message_label)

	extract_button = UIFactory.button("返回方舟", Color("4f8cff"))
	extract_button.position = Vector2(1050, 646)
	extract_button.size = Vector2(210, 52)
	extract_button.visible = false
	extract_button.pressed.connect(func() -> void: _finish(true, "守卫已清除。"))
	layer.add_child(extract_button)
	_build_upgrade_overlay()


func _build_upgrade_overlay() -> void:
	upgrade_layer = CanvasLayer.new()
	upgrade_layer.layer = 40
	upgrade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(upgrade_layer)

	upgrade_overlay = ColorRect.new()
	upgrade_overlay.color = Color(0.01, 0.02, 0.05, 0.9)
	upgrade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_layer.add_child(upgrade_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.add_child(center)

	var layout := VBoxContainer.new()
	layout.custom_minimum_size = Vector2(1000, 0)
	layout.add_theme_constant_override("separation", 22)
	center.add_child(layout)
	var eyebrow := UIFactory.label("A-01 / 异能共振协议", 15, Color("6e9ed9"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(eyebrow)
	var title := UIFactory.label("选择一项行动强化", 30, Color("edf5ff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 18)
	layout.add_child(cards)
	for upgrade: Dictionary in UPGRADES:
		var accent: Color = upgrade["accent"]
		var card := UIFactory.button(
			"%s\n\n%s\n\n选择" % [upgrade["title"], upgrade["description"]],
			accent
		)
		card.custom_minimum_size = Vector2(320, 190)
		card.add_theme_font_size_override("font_size", 19)
		card.pressed.connect(_select_upgrade.bind(upgrade["id"]))
		cards.add_child(card)

	var hint := UIFactory.label("强化仅在本次行动中生效", 14, Color("7789a5"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(hint)
	upgrade_overlay.visible = false


func _spawn_enemy(as_boss: bool) -> void:
	if mission_ended:
		return
	var enemy := Enemy.new()
	var difficulty := 1.0 + elapsed / 100.0
	enemy.configure(player, as_boss, difficulty)
	enemy.position = _random_edge_position()
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)


func _random_edge_position() -> Vector2:
	var side := randi_range(0, 3)
	match side:
		0:
			return Vector2(randf_range(20, 1260), 98)
		1:
			return Vector2(1260, randf_range(100, 700))
		2:
			return Vector2(randf_range(20, 1260), 700)
		_:
			return Vector2(20, randf_range(100, 700))


func _on_enemy_defeated(at_position: Vector2, reward: int, was_boss: bool) -> void:
	kills += 1
	var pickup := Pickup.new()
	pickup.position = at_position
	pickup.target = player
	pickup.amount = reward
	pickup.collected.connect(_on_scrap_collected)
	add_child(pickup)
	if next_upgrade_index < UPGRADE_THRESHOLDS.size() and kills >= UPGRADE_THRESHOLDS[next_upgrade_index]:
		next_upgrade_index += 1
		call_deferred("_offer_upgrade")
	if was_boss:
		boss_defeated = true
		objective_label.text = "守卫已清除，返回方舟"
		message_label.text = "登陆艇导航恢复。带上资源回家。"
		extract_button.visible = true


func _on_scrap_collected(amount: int) -> void:
	recovered_scrap += amount
	if not boss_spawned:
		objective_label.text = "已回收 %d 废料 · 守住阵地" % recovered_scrap


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_player_died() -> void:
	_finish(false, "舰长受伤，A-01 启动了远程撤离。")


func _update_hud() -> void:
	scrap_label.text = "废料 %02d    击破 %02d" % [recovered_scrap, kills]
	var remaining := maxi(int(ceil(MISSION_DURATION - elapsed)), 0)
	time_label.text = "%02d:%02d" % [remaining / 60, remaining % 60]


func _finish(success: bool, reason: String) -> void:
	if mission_ended:
		return
	mission_ended = true
	get_tree().paused = false
	if not success:
		recovered_scrap = int(floor(recovered_scrap * 0.5))
	mission_finished.emit(recovered_scrap, success, reason)


func _offer_upgrade() -> void:
	if mission_ended or upgrade_overlay.visible:
		return
	upgrade_overlay.visible = true
	get_tree().paused = true


func _select_upgrade(upgrade_id: StringName) -> void:
	var result := player.apply_upgrade(upgrade_id)
	message_label.text = result
	upgrade_overlay.visible = false
	get_tree().paused = false
	AudioDirector.play_upgrade()
