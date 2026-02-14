extends Node2D

@export var match_time_limit_seconds: float = 1800.0

var elapsed_time: float = 0.0
var is_match_over: bool = false

func _ready() -> void:
	print("[GameManager] Match initialized")

func _process(delta: float) -> void:
	if is_match_over:
		return

	elapsed_time += delta
	if elapsed_time >= match_time_limit_seconds:
		end_match(false, "Time limit reached")

func end_match(player_won: bool, reason: String) -> void:
	if is_match_over:
		return

	is_match_over = true
	var result := "VICTORY" if player_won else "DEFEAT"
	print("[GameManager] %s - %s" % [result, reason])
