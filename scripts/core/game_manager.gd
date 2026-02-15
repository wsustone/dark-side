extends Node2D

@export var match_time_limit_seconds: float = 1800.0
@export var objective_hold_seconds: float = 180.0
@export var sectors_required_for_objective_win: int = 3
@export var player_flagship_path: NodePath = ^"Flagship"
@export var missile_silo_path: NodePath = ^"MissileSilo"
@export var status_label_path: NodePath = ^"CanvasLayer/MatchStatus"
@export var queue_button_path: NodePath = ^"CanvasLayer/QueueDroneButton"
@export var control_hint_path: NodePath = ^"CanvasLayer/ControlHint"
@export var outpost_scene: PackedScene = preload("res://scenes/buildings/OutpostHub.tscn")
@export var player_starting_metal: float = 250.0
@export var player_starting_energy: float = 220.0
@export var queue_attack_drone_action: StringName = &"ui_accept"
@export var selection_click_radius: float = 26.0
@export var outpost_deploy_range_from_resource: float = 140.0

enum OnboardingStage {
	CAPTURE_FIRST_ISLAND,
	DEPLOY_FIRST_OUTPOST,
	QUEUE_FIRST_DRONE,
	OPEN_PLAY,
}

var elapsed_time: float = 0.0
var is_match_over: bool = false
var objective_hold_elapsed: float = 0.0
var player_metal: float = 0.0
var player_energy: float = 0.0
var _selected_player_drone: Node = null
var _onboarding_stage: int = OnboardingStage.CAPTURE_FIRST_ISLAND

@onready var _status_label: Label = get_node_or_null(status_label_path)
@onready var _queue_button: Button = get_node_or_null(queue_button_path)
@onready var _control_hint: Label = get_node_or_null(control_hint_path)

func _ready() -> void:
	player_metal = player_starting_metal
	player_energy = player_starting_energy
	if _queue_button != null:
		_queue_button.pressed.connect(_on_primary_action_pressed)
		_queue_button.disabled = true
	_update_onboarding_state()
	print("[GameManager] Match initialized")
	_update_status_label()

func _process(delta: float) -> void:
	if is_match_over:
		return

	elapsed_time += delta
	if elapsed_time >= match_time_limit_seconds:
		end_match(false, "Time limit reached")
		return

	var player_flagship := get_node_or_null(player_flagship_path)
	if player_flagship == null:
		end_match(false, "Flagship destroyed")
		return

	_update_objective_control(delta)
	_update_economy(delta)
	_update_onboarding_state()
	_update_status_label()

func _unhandled_input(event: InputEvent) -> void:
	if is_match_over:
		return

	if event is InputEventMouseButton and event.pressed:
		var world_click_position: Vector2 = get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.shift_pressed:
				if _issue_move_order_to_selected_drone(world_click_position):
					get_viewport().set_input_as_handled()
					return
			elif event.ctrl_pressed or event.meta_pressed:
				if _issue_missile_strike(world_click_position):
					get_viewport().set_input_as_handled()
					return
			if _try_select_player_drone_at(world_click_position):
				get_viewport().set_input_as_handled()
				return
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _issue_move_order_to_selected_drone(world_click_position):
				get_viewport().set_input_as_handled()
				return

	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed(queue_attack_drone_action):
		_on_primary_action_pressed()

func _try_select_player_drone_at(world_pos: Vector2) -> bool:
	var nearest_drone: Node2D = null
	var nearest_distance: float = selection_click_radius

	for drone_node: Node in get_tree().get_nodes_in_group("player_drone"):
		var drone := drone_node as Node2D
		if drone == null:
			continue
		var distance := drone.global_position.distance_to(world_pos)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_drone = drone

	if nearest_drone == null:
		_clear_drone_selection()
		return false

	if _selected_player_drone != null and _selected_player_drone.has_method("set_selected"):
		_selected_player_drone.set_selected(false)
	_selected_player_drone = nearest_drone
	if _selected_player_drone.has_method("set_selected"):
		_selected_player_drone.set_selected(true)
	return true

func _issue_move_order_to_selected_drone(world_pos: Vector2) -> bool:
	if _selected_player_drone == null:
		return false
	if not is_instance_valid(_selected_player_drone):
		_selected_player_drone = null
		return false
	if _selected_player_drone.has_method("set_move_target"):
		_selected_player_drone.set_move_target(world_pos)
		return true
	return false

func _issue_missile_strike(world_pos: Vector2) -> bool:
	if _onboarding_stage != OnboardingStage.OPEN_PLAY:
		return false
	var missile_silo := get_node_or_null(missile_silo_path)
	if missile_silo == null:
		return false
	if missile_silo.has_method("begin_lock_on"):
		missile_silo.begin_lock_on(world_pos)
		return true
	return false

func _clear_drone_selection() -> void:
	if _selected_player_drone == null:
		return
	if is_instance_valid(_selected_player_drone) and _selected_player_drone.has_method("set_selected"):
		_selected_player_drone.set_selected(false)
	_selected_player_drone = null

func _update_economy(delta: float) -> void:
	for node in get_tree().get_nodes_in_group("resource_node"):
		if node.has_method("get_metal_rate_for_team"):
			player_metal += node.get_metal_rate_for_team("player") * delta
		if node.has_method("get_energy_rate_for_team"):
			player_energy += node.get_energy_rate_for_team("player") * delta

func _update_objective_control(delta: float) -> void:
	var player_owned_sectors := 0
	for sector in get_tree().get_nodes_in_group("objective_sector"):
		if sector.has_method("get_owner_team") and sector.get_owner_team() == "player":
			player_owned_sectors += 1

	if player_owned_sectors >= sectors_required_for_objective_win:
		objective_hold_elapsed += delta
		if objective_hold_elapsed >= objective_hold_seconds:
			end_match(true, "Objective sectors held")
	else:
		objective_hold_elapsed = 0.0

func _update_status_label() -> void:
	if _status_label == null:
		return

	var player_owned_sectors := 0
	for sector in get_tree().get_nodes_in_group("objective_sector"):
		if sector.has_method("get_owner_team") and sector.get_owner_team() == "player":
			player_owned_sectors += 1

	var hold_display: float = minf(objective_hold_elapsed, objective_hold_seconds)
	_status_label.text = "Time: %.0fs | Metal: %.0f | Energy: %.0f | Sectors: %d/%d | Hold: %.0fs/%.0fs" % [
		elapsed_time,
		player_metal,
		player_energy,
		player_owned_sectors,
		sectors_required_for_objective_win,
		hold_display,
		objective_hold_seconds,
	]

func _update_onboarding_state() -> void:
	if _onboarding_stage == OnboardingStage.CAPTURE_FIRST_ISLAND and _count_player_owned_resource_nodes() > 0:
		_onboarding_stage = OnboardingStage.DEPLOY_FIRST_OUTPOST

	if _onboarding_stage == OnboardingStage.DEPLOY_FIRST_OUTPOST and _count_player_outposts() > 0:
		_onboarding_stage = OnboardingStage.QUEUE_FIRST_DRONE

	if _onboarding_stage == OnboardingStage.QUEUE_FIRST_DRONE and _count_player_drones() > 0:
		_onboarding_stage = OnboardingStage.OPEN_PLAY

	if _queue_button != null:
		_queue_button.disabled = false
		if _onboarding_stage == OnboardingStage.CAPTURE_FIRST_ISLAND:
			_queue_button.disabled = true
			_queue_button.text = "Capture Island First"
		elif _onboarding_stage == OnboardingStage.DEPLOY_FIRST_OUTPOST:
			_queue_button.text = "Deploy First Outpost"
		else:
			_queue_button.text = "Queue Attack Drone"

	var missile_silo := get_node_or_null(missile_silo_path)
	if missile_silo != null:
		var missiles_unlocked := _onboarding_stage == OnboardingStage.OPEN_PLAY
		missile_silo.commands_enabled = missiles_unlocked
		missile_silo.visible = missiles_unlocked

	if _control_hint == null:
		return

	match _onboarding_stage:
		OnboardingStage.CAPTURE_FIRST_ISLAND:
			_control_hint.text = "Phase 1: Left-click to move your command ship and capture a resource node."
		OnboardingStage.DEPLOY_FIRST_OUTPOST:
			_control_hint.text = "Phase 2: Move onto the captured island, then press Deploy First Outpost."
		OnboardingStage.QUEUE_FIRST_DRONE:
			_control_hint.text = "Phase 3: Queue your first drone from the button to start your fleet (missiles unlock next)."
		_:
			_control_hint.text = "Open Play: Left-click move/select | Shift+click order | Cmd/Ctrl+click missile | Space+drag pan"

func _count_player_owned_resource_nodes() -> int:
	var owned_count: int = 0
	for node in get_tree().get_nodes_in_group("resource_node"):
		if node.has_method("get_owner_team") and node.get_owner_team() == "player":
			owned_count += 1
	return owned_count

func _count_player_drones() -> int:
	return get_tree().get_nodes_in_group("player_drone").size()

func _count_player_outposts() -> int:
	var count: int = 0
	for outpost in get_tree().get_nodes_in_group("outpost_hub"):
		if outpost.has_method("get_owner_team") and outpost.get_owner_team() == "player":
			count += 1
	return count

func is_open_play() -> bool:
	return _onboarding_stage == OnboardingStage.OPEN_PLAY

func _on_primary_action_pressed() -> void:
	if _onboarding_stage == OnboardingStage.DEPLOY_FIRST_OUTPOST:
		if _try_deploy_first_outpost():
			print("[GameManager] First outpost deployed")
		else:
			print("[GameManager] Move onto your captured island before deploying outpost")
		return
	_queue_attack_drone_from_player_outpost()

func _try_deploy_first_outpost() -> bool:
	if outpost_scene == null:
		return false
	if _count_player_outposts() > 0:
		return false

	var owned_resource_inside: Node2D = null
	for node in get_tree().get_nodes_in_group("resource_node"):
		if not node.has_method("get_owner_team") or node.get_owner_team() != "player":
			continue
		if not node.has_method("is_player_unit_inside") or not node.is_player_unit_inside():
			continue
		if node is Node2D:
			owned_resource_inside = node as Node2D
			break

	if owned_resource_inside == null:
		return false

	var outpost_instance := outpost_scene.instantiate() as Node2D
	if outpost_instance == null:
		return false

	add_child(outpost_instance)
	outpost_instance.global_position = owned_resource_inside.global_position + Vector2(72.0, 0.0)
	outpost_instance.name = "PlayerOutpost"
	return true

func can_place_building_at(world_position: Vector2, team_name: String = "player") -> bool:
	for outpost in get_tree().get_nodes_in_group("outpost_hub"):
		if not outpost.has_method("get_owner_team"):
			continue
		if outpost.get_owner_team() != team_name:
			continue
		if outpost.has_method("is_point_in_influence") and outpost.is_point_in_influence(world_position):
			return true
	return false

func can_afford(cost_metal: float, cost_energy: float) -> bool:
	return player_metal >= cost_metal and player_energy >= cost_energy

func spend_resources(cost_metal: float, cost_energy: float) -> bool:
	if not can_afford(cost_metal, cost_energy):
		return false
	player_metal -= cost_metal
	player_energy -= cost_energy
	return true

func _queue_attack_drone_from_player_outpost() -> void:
	if _onboarding_stage == OnboardingStage.CAPTURE_FIRST_ISLAND:
		print("[GameManager] Capture a resource node first to unlock production")
		return
	if _onboarding_stage == OnboardingStage.DEPLOY_FIRST_OUTPOST:
		print("[GameManager] Deploy your first outpost before queuing drones")
		return

	for outpost in get_tree().get_nodes_in_group("outpost_hub"):
		if not outpost.has_method("get_owner_team"):
			continue
		if outpost.get_owner_team() != "player":
			continue
		if outpost.has_method("try_enqueue_attack_drone") and outpost.try_enqueue_attack_drone(self):
			print("[GameManager] Queued AttackDrone at %s" % [outpost.name])
			return
	print("[GameManager] Could not queue AttackDrone (no valid outpost or insufficient resources)")

func end_match(player_won: bool, reason: String) -> void:
	if is_match_over:
		return

	is_match_over = true
	var result := "VICTORY" if player_won else "DEFEAT"
	print("[GameManager] %s - %s" % [result, reason])
	if _status_label != null:
		_status_label.text = "%s - %s" % [result, reason]
