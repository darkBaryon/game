class_name ExpeditionPlayer
extends Node2D

signal health_changed(current: float, maximum: float)
signal died

const Bullet := preload("res://scripts/expedition/bullet.gd")

var max_health: float = 100.0
var health: float = 100.0
var move_speed: float = 265.0
var attack_damage: float = 16.0
var attack_interval: float = 0.48
var attack_range: float = 430.0

var _attack_cooldown: float = 0.12
var _hurt_flash: float = 0.0
var _invulnerability: float = 0.0
var upgrade_count: int = 0


func _ready() -> void:
	z_index = 10
	queue_redraw()


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += direction * move_speed * delta
	position.x = clampf(position.x, 38.0, 1242.0)
	position.y = clampf(position.y, 86.0, 682.0)

	_attack_cooldown -= delta
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_invulnerability = maxf(_invulnerability - delta, 0.0)
	if _attack_cooldown <= 0.0:
		_auto_attack()
	queue_redraw()


func take_damage(amount: float) -> void:
	if _invulnerability > 0.0 or health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	_hurt_flash = 0.14
	_invulnerability = 0.34
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)


func apply_upgrade(upgrade_id: StringName) -> String:
	upgrade_count += 1
	match upgrade_id:
		&"overcharge":
			attack_damage *= 1.4
			return "等离子过载：武器伤害提升 40%"
		&"rapid_fire":
			attack_interval = maxf(attack_interval * 0.76, 0.16)
			return "脉冲供能：自动攻击间隔缩短 24%"
		&"nanoshield":
			max_health += 35.0
			health = minf(health + 55.0, max_health)
			health_changed.emit(health, max_health)
			return "纳米护盾：生命上限 +35 并恢复生命"
	return "未知强化"


func _auto_attack() -> void:
	var closest: Node2D
	var closest_distance := attack_range
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not is_instance_valid(candidate):
			continue
		var enemy := candidate as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest = enemy
			closest_distance = distance
	if closest == null:
		return

	_attack_cooldown = attack_interval
	var bullet := Bullet.new()
	bullet.global_position = global_position
	bullet.direction = global_position.direction_to(closest.global_position)
	bullet.damage = attack_damage
	get_parent().add_child(bullet)
	AudioDirector.play_shot()


func _draw() -> void:
	var body_color := Color("ffffff") if _hurt_flash <= 0.0 else Color("ff6b6b")
	draw_circle(Vector2(3, 6), 21, Color(0, 0, 0, 0.35))
	draw_circle(Vector2.ZERO, 20, Color("1a2b49"))
	draw_arc(Vector2.ZERO, 21, 0, TAU, 40, Color("5aa9ff"), 3.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -17), Vector2(-11, 10), Vector2(0, 5), Vector2(11, 10)]), body_color)
	draw_circle(Vector2(0, -4), 5, Color("69c6ff"))
	if _invulnerability > 0.0:
		draw_arc(Vector2.ZERO, 28, 0, TAU, 48, Color(0.4, 0.8, 1.0, 0.5), 2.0, true)
