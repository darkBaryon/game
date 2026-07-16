class_name ScrapPickup
extends Node2D

signal collected(amount: int)

var target: ExpeditionPlayer
var amount: int = 3
var _age: float = 0.0


func _ready() -> void:
	z_index = 4
	queue_redraw()


func _physics_process(delta: float) -> void:
	_age += delta
	if not is_instance_valid(target):
		return
	var distance := global_position.distance_to(target.global_position)
	var pickup_radius := target.pickup_radius
	if distance < pickup_radius:
		var pull_speed := lerpf(90.0, 520.0, 1.0 - distance / pickup_radius)
		global_position += global_position.direction_to(target.global_position) * pull_speed * delta
	if distance < 23.0:
		AudioDirector.play_pickup()
		collected.emit(amount)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(_age * 6.0) * 0.12
	var points := PackedVector2Array([
		Vector2(0, -9) * pulse,
		Vector2(8, 0) * pulse,
		Vector2(0, 9) * pulse,
		Vector2(-8, 0) * pulse,
	])
	draw_colored_polygon(points, Color("69d7ff"))
	draw_polyline(points + PackedVector2Array([points[0]]), Color("d8f8ff"), 2.0)
