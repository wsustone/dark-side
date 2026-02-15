extends Node

enum BotState { EXPAND, DEFEND, ATTACK }

@export var state: BotState = BotState.EXPAND
@export var enemy_outpost_path: NodePath = ^"../EnemyOutpost"
@export var player_flagship_path: NodePath = ^"../Flagship"
@export var command_interval_seconds: float = 1.2
@export var queue_interval_seconds: float = 7.0
@export var max_enemy_drones: int = 8
@export var attack_threshold_drones: int = 4
@export var defend_radius: float = 360.0

var _command_timer: float = 0.0
var _queue_timer: float = 0.0

func _process(delta: float) -> void:
	var game_manager := get_node_or_null("../")
	if game_manager != null and game_manager.has_method("is_open_play"):
		if not game_manager.is_open_play():
			return
	var enemy_outpost: Node2D = get_node_or_null(enemy_outpost_path) as Node2D
	if enemy_outpost == null:
		return

	_queue_timer += delta
	if _queue_timer >= queue_interval_seconds:
		_queue_timer = 0.0
		_try_queue_enemy_drone(enemy_outpost)

	_update_state(enemy_outpost)

	_command_timer += delta
	if _command_timer >= command_interval_seconds:
		_command_timer = 0.0
		_issue_orders(enemy_outpost)

func _try_queue_enemy_drone(enemy_outpost: Node2D) -> void:
	var enemy_drone_count: int = get_tree().get_nodes_in_group("enemy_drone").size()
	if enemy_drone_count >= max_enemy_drones:
		return
	if enemy_outpost.has_method("try_enqueue_attack_drone_ai"):
		enemy_outpost.try_enqueue_attack_drone_ai()

func _update_state(enemy_outpost: Node2D) -> void:
	var enemy_drone_count: int = get_tree().get_nodes_in_group("enemy_drone").size()
	if enemy_drone_count >= attack_threshold_drones:
		state = BotState.ATTACK
		return

	var player_flagship := get_node_or_null(player_flagship_path) as Node2D
	if player_flagship != null:
		var distance_to_flagship: float = enemy_outpost.global_position.distance_to(player_flagship.global_position)
		if distance_to_flagship <= defend_radius:
			state = BotState.DEFEND
			return

	state = BotState.EXPAND

func _issue_orders(enemy_outpost: Node2D) -> void:
	var target_position: Vector2 = enemy_outpost.global_position
	match state:
		BotState.EXPAND:
			target_position = _get_expand_target(enemy_outpost.global_position)
		BotState.DEFEND:
			target_position = enemy_outpost.global_position
		BotState.ATTACK:
			target_position = _get_attack_target(enemy_outpost.global_position)

	var index: int = 0
	for drone_node: Node in get_tree().get_nodes_in_group("enemy_drone"):
		if not drone_node.has_method("set_move_target"):
			continue
		var spread := Vector2(18.0 * float(index % 3), 18.0 * float(index / 3))
		drone_node.set_move_target(target_position + spread)
		index += 1

func _get_expand_target(fallback: Vector2) -> Vector2:
	for node in get_tree().get_nodes_in_group("resource_node"):
		if node.has_method("get_owner_team") and node.get_owner_team() != "enemy":
			if node is Node2D:
				return (node as Node2D).global_position
	return fallback

func _get_attack_target(fallback: Vector2) -> Vector2:
	var player_flagship: Node2D = get_node_or_null(player_flagship_path) as Node2D
	if player_flagship != null:
		return player_flagship.global_position

	for outpost in get_tree().get_nodes_in_group("outpost_hub"):
		if outpost.has_method("get_owner_team") and outpost.get_owner_team() == "player":
			if outpost is Node2D:
				return (outpost as Node2D).global_position

	for node in get_tree().get_nodes_in_group("resource_node"):
		if node.has_method("get_owner_team") and node.get_owner_team() == "player":
			if node is Node2D:
				return (node as Node2D).global_position

	return fallback
