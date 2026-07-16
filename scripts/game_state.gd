extends Node

signal changed

const SAVE_PATH := "user://starship_spark_save.json"

var scrap: int = 12
var energy: int = 3
var reactor_repaired: bool = false
var habitat_repaired: bool = false
var quarters_repaired: bool = false
var mission_count: int = 0
var intro_seen: bool = false
var persistence_enabled: bool = true


func _ready() -> void:
	load_game()


func repair_reactor() -> bool:
	if reactor_repaired or scrap < 8:
		return false
	scrap -= 8
	energy = 15
	reactor_repaired = true
	_commit()
	return true


func repair_habitat() -> bool:
	if habitat_repaired or not reactor_repaired or scrap < 18:
		return false
	scrap -= 18
	habitat_repaired = true
	_commit()
	return true


func repair_quarters() -> bool:
	if quarters_repaired or not habitat_repaired or scrap < 30:
		return false
	scrap -= 30
	quarters_repaired = true
	_commit()
	return true


func complete_mission(recovered_scrap: int) -> void:
	scrap += maxi(recovered_scrap, 0)
	energy = maxi(energy - 2, 0)
	mission_count += 1
	_commit()


func mark_intro_seen() -> void:
	if intro_seen:
		return
	intro_seen = true
	_commit()


func reset_progress() -> void:
	scrap = 12
	energy = 3
	reactor_repaired = false
	habitat_repaired = false
	quarters_repaired = false
	mission_count = 0
	intro_seen = false
	_commit()


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file: %s" % SAVE_PATH)
		return
	var data := {
		"scrap": scrap,
		"energy": energy,
		"reactor_repaired": reactor_repaired,
		"habitat_repaired": habitat_repaired,
		"quarters_repaired": quarters_repaired,
		"mission_count": mission_count,
		"intro_seen": intro_seen,
	}
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data := parsed as Dictionary
	scrap = int(data.get("scrap", scrap))
	energy = int(data.get("energy", energy))
	reactor_repaired = bool(data.get("reactor_repaired", reactor_repaired))
	habitat_repaired = bool(data.get("habitat_repaired", habitat_repaired))
	quarters_repaired = bool(data.get("quarters_repaired", quarters_repaired))
	mission_count = int(data.get("mission_count", mission_count))
	intro_seen = bool(data.get("intro_seen", intro_seen))


func _commit() -> void:
	if persistence_enabled:
		save_game()
	changed.emit()
