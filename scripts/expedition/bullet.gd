class_name ExpeditionBullet
extends Node2D

var direction := Vector2.RIGHT
var speed: float = 720.0
var damage: float = 16.0
var lifetime: float = 1.0


func _ready() -> void:
	z_index = 7
	rotation = direction.angle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		if not candidate is ExpeditionEnemy or not is_instance_valid(candidate):
			continue
		var enemy := candidate as ExpeditionEnemy
		var hit_radius := 50.0 if enemy.is_boss else 23.0
		if global_position.distance_to(enemy.global_position) <= hit_radius:
			enemy.take_damage(damage)
			queue_free()
			return
	if lifetime <= 0.0 or position.x < -30 or position.x > 1310 or position.y < 40 or position.y > 750:
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-12, 0), Vector2(9, 0), Color(0.35, 0.75, 1.0, 0.35), 8.0)
	draw_line(Vector2(-8, 0), Vector2(10, 0), Color("b9efff"), 3.0)
	draw_circle(Vector2(10, 0), 4, Color.WHITE)
