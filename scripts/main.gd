extends Node

const ShipView := preload("res://scripts/ship/ship_view.gd")
const ExpeditionView := preload("res://scripts/expedition/expedition_view.gd")
const OpeningView := preload("res://scripts/opening/opening_view.gd")

var current_view: Node


func _ready() -> void:
	_configure_input()
	if GameState.intro_seen:
		show_ship()
	else:
		show_opening()


func show_opening() -> void:
	_replace_current_view()
	var opening := OpeningView.new()
	opening.completed.connect(_finish_opening)
	add_child(opening)
	current_view = opening


func show_ship(report: String = "") -> void:
	_replace_current_view()
	var ship := ShipView.new()
	ship.launch_requested.connect(_start_expedition)
	ship.reset_requested.connect(_reset_progress)
	ship.mission_report = report
	add_child(ship)
	current_view = ship


func _start_expedition() -> void:
	if not GameState.reactor_repaired:
		return
	_replace_current_view()
	var expedition := ExpeditionView.new()
	expedition.mission_finished.connect(_finish_expedition)
	add_child(expedition)
	current_view = expedition
	AudioDirector.play_launch()


func _finish_opening() -> void:
	GameState.mark_intro_seen()
	show_ship("A-01：舰长权限恢复。方舟-01 等待您的指令。")


func _finish_expedition(recovered_scrap: int, success: bool, reason: String) -> void:
	GameState.complete_mission(recovered_scrap)
	var report := "任务完成：回收 %d 单位废料。%s" % [recovered_scrap, reason]
	if not success:
		report = "紧急撤离：保住了 %d 单位废料。%s" % [recovered_scrap, reason]
	show_ship(report)


func _reset_progress() -> void:
	GameState.reset_progress()
	show_ship("A-01：时间线已重置，等待舰长重新下令。")


func _replace_current_view() -> void:
	if is_instance_valid(current_view):
		remove_child(current_view)
		current_view.queue_free()
	current_view = null


func _configure_input() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])


func _add_key_action(action: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
