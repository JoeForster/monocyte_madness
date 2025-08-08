extends Node

@export var move_thrust_min = 600.0
@export var move_thrust_max = 1000.0
@export var move_period_min = 1
@export var move_period_max = 2
@export var pause_period_min = 2
@export var pause_period_max = 4

func _process(_delta: float) -> void:
	# Check all infected cells and determine largest
	var all_neutrals = get_tree().get_nodes_in_group("neutrals")

	for ai_cell in all_neutrals:
		ai_cell.ai_state_timer -= _delta
		if ai_cell.ai_state_timer <= 0.0:
			var was_wandering = ai_cell.ai_state == Cell.CELL_AI_STATE.WANDERING
			if was_wandering:
				ai_cell.ai_state = Cell.CELL_AI_STATE.PAUSED
				ai_cell.ai_state_timer = randf_range(pause_period_min, pause_period_max)
				ai_cell.ai_thrust = Vector2.ZERO
			else:
				ai_cell.ai_state = Cell.CELL_AI_STATE.WANDERING
				ai_cell.ai_state_timer = randf_range(move_period_min, move_period_max)
				ai_cell.ai_thrust = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(move_thrust_min, move_thrust_max)
