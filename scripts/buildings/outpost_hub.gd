extends Node2D

enum TeamOwner {
	NEUTRAL,
	PLAYER,
	ENEMY,
}

@export var team_owner: TeamOwner = TeamOwner.PLAYER
@export var influence_radius: float = 260.0
@export var attack_drone_scene: PackedScene
@export var attack_drone_build_time_seconds: float = 4.0
@export var attack_drone_cost_metal: float = 45.0
@export var attack_drone_cost_energy: float = 30.0
@export var rally_point_local: Vector2 = Vector2(85.0, 0.0)

var _queue: Array[String] = []
var _queue_progress_seconds: float = 0.0

func _ready() -> void:
	add_to_group("outpost_hub")
	queue_redraw()

func _process(delta: float) -> void:
	if _queue.is_empty():
		_queue_progress_seconds = 0.0
		return

	_queue_progress_seconds += delta
	if _queue_progress_seconds >= attack_drone_build_time_seconds:
		_queue_progress_seconds = 0.0
		var unit_id: String = String(_queue.pop_front())
		_spawn_queued_unit(unit_id)

func get_owner_team() -> String:
	match team_owner:
		TeamOwner.PLAYER:
			return "player"
		TeamOwner.ENEMY:
			return "enemy"
		_:
			return "neutral"

func is_point_in_influence(world_position: Vector2) -> bool:
	return global_position.distance_to(world_position) <= influence_radius

func try_enqueue_attack_drone(game_manager: Node) -> bool:
	if attack_drone_scene == null:
		return false
	if game_manager == null or not game_manager.has_method("spend_resources"):
		return false
	if not game_manager.spend_resources(attack_drone_cost_metal, attack_drone_cost_energy):
		return false
	_queue.append("attack_drone")
	return true

func try_enqueue_attack_drone_ai() -> bool:
	if attack_drone_scene == null:
		return false
	_queue.append("attack_drone")
	return true

func get_queue_size() -> int:
	return _queue.size()

func _spawn_queued_unit(unit_id: String) -> void:
	if unit_id != "attack_drone":
		return

	if attack_drone_scene == null:
		return

	var spawned_unit := attack_drone_scene.instantiate()
	if spawned_unit == null:
		return

	get_parent().add_child(spawned_unit)
	spawned_unit.global_position = global_position + rally_point_local

	var team_name := get_owner_team()
	if team_name == "player":
		spawned_unit.add_to_group("player_unit")
		spawned_unit.add_to_group("player_drone")
	elif team_name == "enemy":
		spawned_unit.add_to_group("enemy_unit")
		spawned_unit.add_to_group("enemy_drone")

	if spawned_unit.has_method("set_move_target"):
		spawned_unit.set_move_target(spawned_unit.global_position)

func _draw() -> void:
	var fill_color := Color(0.45, 0.48, 0.56, 0.2)
	if team_owner == TeamOwner.PLAYER:
		fill_color = Color(0.1, 0.78, 1.0, 0.2)
	elif team_owner == TeamOwner.ENEMY:
		fill_color = Color(1.0, 0.38, 0.35, 0.2)
	draw_circle(Vector2.ZERO, influence_radius, fill_color)
	draw_arc(Vector2.ZERO, influence_radius, 0.0, TAU, 72, Color(0.92, 0.95, 1.0, 0.45), 2.0)
