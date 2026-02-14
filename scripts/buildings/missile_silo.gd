extends Node2D

@export var cooldown_seconds: float = 18.0
@export var impact_damage: float = 300.0

var cooldown_remaining: float = 0.0

func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)

func can_fire() -> bool:
	return cooldown_remaining <= 0.0

func fire_at(target_world_position: Vector2) -> void:
	if not can_fire():
		return
	cooldown_remaining = cooldown_seconds
	print("[MissileSilo] Firing at %s for %.1f damage" % [target_world_position, impact_damage])
