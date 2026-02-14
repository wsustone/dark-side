extends Node

enum BotState { EXPAND, DEFEND, ATTACK }

@export var state: BotState = BotState.EXPAND

func _process(_delta: float) -> void:
	match state:
		BotState.EXPAND:
			# TODO: Claim nearest available resource nodes.
			pass
		BotState.DEFEND:
			# TODO: Reinforce threatened structures.
			pass
		BotState.ATTACK:
			# TODO: Launch force toward player frontier.
			pass
