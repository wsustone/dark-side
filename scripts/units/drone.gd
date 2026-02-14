extends CharacterBody2D

@export var move_speed: float = 320.0
@export var max_health: float = 120.0
@export var attack_damage: float = 12.0

var health: float
var target_position: Vector2

func _ready() -> void:
	health = max_health
	target_position = global_position

func _physics_process(_delta: float) -> void:
	var to_target := target_position - global_position
	if to_target.length() > 4.0:
		velocity = to_target.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func set_move_target(world_pos: Vector2) -> void:
	target_position = world_pos

func apply_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	if health <= 0.0:
		queue_free()
