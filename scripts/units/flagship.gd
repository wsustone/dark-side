extends CharacterBody2D

@export var move_speed: float = 260.0
@export var max_health: float = 2000.0

var health: float
var target_position: Vector2

func _ready() -> void:
	add_to_group("player_unit")
	health = max_health
	target_position = global_position

func _physics_process(_delta: float) -> void:
	var to_target := target_position - global_position
	if to_target.length() > 4.0:
		velocity = to_target.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		set_move_target(get_global_mouse_position())

func set_move_target(world_pos: Vector2) -> void:
	target_position = world_pos

func apply_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	if health <= 0.0:
		queue_free()
