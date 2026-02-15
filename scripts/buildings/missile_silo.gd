extends Node2D

@export var cooldown_seconds: float = 18.0
@export var lock_time_seconds: float = 2.0
@export var energy_spike_cost: float = 220.0
@export var impact_damage: float = 300.0
@export var commands_enabled: bool = true

var cooldown_remaining: float = 0.0
var lock_remaining: float = 0.0
var pending_target_world_position: Vector2 = Vector2.ZERO
var has_pending_target: bool = false

func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)

	if lock_remaining > 0.0:
		lock_remaining = max(0.0, lock_remaining - delta)
		if lock_remaining <= 0.0 and has_pending_target:
			fire_at(pending_target_world_position)

	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not commands_enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		begin_lock_on(get_global_mouse_position())

func can_fire() -> bool:
	return cooldown_remaining <= 0.0 and lock_remaining <= 0.0

func begin_lock_on(target_world_position: Vector2) -> void:
	if not commands_enabled:
		return
	if not can_fire():
		return
	lock_remaining = lock_time_seconds
	has_pending_target = true
	pending_target_world_position = target_world_position
	print("[MissileSilo] Locking target at %s" % [target_world_position])

func fire_at(target_world_position: Vector2) -> void:
	if cooldown_remaining > 0.0:
		return
	cooldown_remaining = cooldown_seconds
	has_pending_target = false
	lock_remaining = 0.0
	print("[MissileSilo] Firing at %s for %.1f damage (energy spike %.1f)" % [target_world_position, impact_damage, energy_spike_cost])

func _draw() -> void:
	if has_pending_target and lock_remaining > 0.0:
		var pulse := 0.2 + 0.25 * (1.0 + sin(Time.get_ticks_msec() / 110.0))
		var indicator_color := Color(1.0, 0.3, 0.2, pulse)
		draw_circle(to_local(pending_target_world_position), 24.0, indicator_color)
		draw_arc(to_local(pending_target_world_position), 28.0, 0.0, TAU, 42, Color(1.0, 0.8, 0.75, 0.8), 2.0)
