extends Camera2D

@export var pan_speed: float = 900.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.6
@export var max_zoom: float = 2.0

func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if direction != Vector2.ZERO:
		global_position += direction.normalized() * pan_speed * delta

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_page_up"):
		apply_zoom(-zoom_step)
	elif event.is_action_pressed("ui_page_down"):
		apply_zoom(zoom_step)

func apply_zoom(delta_zoom: float) -> void:
	var next_zoom := clamp(zoom.x + delta_zoom, min_zoom, max_zoom)
	zoom = Vector2(next_zoom, next_zoom)
