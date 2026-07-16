extends Node

const ShipView := preload("res://scripts/ship/ship_view.gd")


func _ready() -> void:
	GameState.persistence_enabled = false
	GameState.scrap = 16
	GameState.energy = 9
	GameState.mission_count = 3
	GameState.reactor_repaired = true
	GameState.habitat_repaired = true
	GameState.quarters_repaired = true
	var ship := ShipView.new()
	ship.mission_report = "A-01：居民舱生命支持恢复。林岚的休眠舱已经打开。"
	add_child(ship)
