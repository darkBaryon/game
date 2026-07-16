class_name ExpeditionEnemy
extends Node2D

signal defeated(position: Vector2, reward: int, was_boss: bool)

var target: ExpeditionPlayer
var is_boss: bool = false
var max_health: float = 38.0
var health: float = 38.0
var speed: float = 72.0
var contact_damage: float = 9.0
var reward: int = 3

var _attack_cooldown: float = 0.0
var _hit_flash: float = 0.0


func configure(player: ExpeditionPlayer, boss: bool, difficulty: float = 1.0) -> void:
	target = player
	is_boss = boss
	if is_boss:
		max_health = 360.0
		health = max_health
		speed = 52.0
		contact_damage = 18.0
		reward = 12
	else:
		max_health *= difficulty
		health = max_health
		speed += minf((difficulty - 1.0) * 20.0, 45.0)
		reward = 3


func _ready() -> void:
	add_to_group("enemies")
	z_index = 5 if not is_boss else 8
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or health <= 0.0:
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	var distance := global_position.distance_to(target.global_position)
	if distance > (46.0 if is_boss else 29.0):
		global_position += global_position.direction_to(target.global_position) * speed * delta
	elif _attack_cooldown <= 0.0:
		target.take_damage(contact_damage)
		_attack_cooldown = 0.8 if is_boss else 1.0
	queue_redraw()


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	_hit_flash = 0.1
	if health <= 0.0:
		AudioDirector.play_defeat(is_boss)
		defeated.emit(global_position, reward, is_boss)
		queue_free()


func _draw() -> void:
	var radius := 42.0 if is_boss else 17.0
	var color := Color("fff0f0") if _hit_flash > 0.0 else (Color("bd4b62") if is_boss else Color("703c68"))
	draw_circle(Vector2(3, 6), radius, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius + 2, 0, TAU, 36, Color("ff6b81"), 2.0, true)
	var eye_offset := 12.0 if is_boss else 5.0
	draw_circle(Vector2(-eye_offset, -4), 3.5, Color("ffdb6e"))
	draw_circle(Vector2(eye_offset, -4), 3.5, Color("ffdb6e"))
	if is_boss:
		for index in 8:
			var angle := TAU * float(index) / 8.0
			var outer := Vector2.from_angle(angle) * 55
			var inner := Vector2.from_angle(angle) * 41
			draw_line(inner, outer, Color("ff6b81"), 5.0)
		var ratio := health / max_health
		draw_rect(Rect2(Vector2(-48, -58), Vector2(96, 7)), Color("301923"), true)
		draw_rect(Rect2(Vector2(-48, -58), Vector2(96 * ratio, 7)), Color("ff667d"), true)
