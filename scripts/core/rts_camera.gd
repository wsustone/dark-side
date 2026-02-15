extends Camera2D

@export var pan_speed: float = 900.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.6
@export var max_zoom: float = 2.0

var _is_drag_panning: bool = false

func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	if direction != Vector2.ZERO:
		global_position += direction.normalized() * pan_speed * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_drag_panning = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SPACE):
			_is_drag_panning = event.pressed
	if event is InputEventMouseMotion and _is_drag_panning:
		global_position -= event.relative * zoom.x

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		apply_zoom(-zoom_step)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		apply_zoom(zoom_step)

func apply_zoom(delta_zoom: float) -> void:
	var next_zoom: float = clampf(zoom.x + delta_zoom, min_zoom, max_zoom)
	zoom = Vector2(next_zoom, next_zoom)
