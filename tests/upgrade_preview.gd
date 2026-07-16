extends "res://scripts/expedition/expedition_view.gd"


func _ready() -> void:
	super._ready()
	call_deferred("_offer_upgrade")


func _exit_tree() -> void:
	get_tree().paused = false
	AudioDirector.stop_all()
