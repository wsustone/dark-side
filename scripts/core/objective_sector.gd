extends Area2D

signal owner_changed(new_owner: String)

enum TeamOwner {
	NEUTRAL,
	PLAYER,
	ENEMY,
}

@export var capture_time_seconds: float = 4.0

var team_owner: TeamOwner = TeamOwner.NEUTRAL
var _player_units_inside: int = 0
var _enemy_units_inside: int = 0
var _capture_progress: float = 0.0
var _capturing_team: TeamOwner = TeamOwner.NEUTRAL

func _ready() -> void:
	add_to_group("objective_sector")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _process(delta: float) -> void:
	var next_capturing_team := _resolve_capturing_team()
	if next_capturing_team == TeamOwner.NEUTRAL:
		_capture_progress = max(0.0, _capture_progress - delta)
		_capturing_team = TeamOwner.NEUTRAL
		return

	if next_capturing_team != _capturing_team:
		_capture_progress = 0.0
		_capturing_team = next_capturing_team

	_capture_progress += delta
	if _capture_progress >= capture_time_seconds:
		_capture_progress = 0.0
		_set_owner(_capturing_team)
		_capturing_team = TeamOwner.NEUTRAL

func get_owner_team() -> String:
	match team_owner:
		TeamOwner.PLAYER:
			return "player"
		TeamOwner.ENEMY:
			return "enemy"
		_:
			return "neutral"

func _resolve_capturing_team() -> TeamOwner:
	if _player_units_inside > 0 and _enemy_units_inside == 0 and team_owner != TeamOwner.PLAYER:
		return TeamOwner.PLAYER
	if _enemy_units_inside > 0 and _player_units_inside == 0 and team_owner != TeamOwner.ENEMY:
		return TeamOwner.ENEMY
	return TeamOwner.NEUTRAL

func _set_owner(new_owner: TeamOwner) -> void:
	if team_owner == new_owner:
		return
	team_owner = new_owner
	owner_changed.emit(get_owner_team())
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player_unit"):
		_player_units_inside += 1
	elif body.is_in_group("enemy_unit"):
		_enemy_units_inside += 1

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player_unit"):
		_player_units_inside = max(0, _player_units_inside - 1)
	elif body.is_in_group("enemy_unit"):
		_enemy_units_inside = max(0, _enemy_units_inside - 1)

func _draw() -> void:
	var fill_color := Color(0.6, 0.6, 0.65, 0.2)
	if team_owner == TeamOwner.PLAYER:
		fill_color = Color(0.1, 0.8, 1.0, 0.25)
	elif team_owner == TeamOwner.ENEMY:
		fill_color = Color(1.0, 0.3, 0.3, 0.25)
	draw_circle(Vector2.ZERO, 80.0, fill_color)
	draw_arc(Vector2.ZERO, 80.0, 0.0, TAU, 48, Color(0.85, 0.9, 1.0, 0.65), 2.0)
