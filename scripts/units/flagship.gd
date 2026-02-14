extends CharacterBody2D

@export var move_speed: float = 260.0
@export var max_health: float = 2000.0

var health: float

func _ready() -> void:
	health = max_health

func _physics_process(_delta: float) -> void:
	# Placeholder direct-control movement for prototype phase.
	# This will be replaced by RTS command movement once selection/order systems are wired.
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	velocity = input_vector.normalized() * move_speed if input_vector != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

func apply_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	if health <= 0.0:
		queue_free()
