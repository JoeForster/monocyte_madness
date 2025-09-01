extends Node

@export var next_level_path : String
@export var next_level_time = 3.0
@export var timer_label : Label

var level_timer = 0.0
var pending_level_path : String
var pending_level_timer = next_level_time


func _update_game_over(delta: float) -> void:
	if pending_level_path:
		pending_level_timer -= delta
		if pending_level_timer <= 0:
			# End the level.
			var num_infected = 0
			var total_infected_size = 0.0
			var biggest_infected = 0.0
			for infected in get_tree().get_nodes_in_group("infected"):
				var infected_cell = infected as Cell
				if infected_cell:
					num_infected += 1
					total_infected_size += infected_cell.size
					if infected_cell.size > biggest_infected:
						biggest_infected = infected_cell.size
			GameProgression.add_level_results(num_infected, total_infected_size, biggest_infected, level_timer)
			
			get_tree().change_scene_to_file(pending_level_path)
	else:
		level_timer += delta
		
		if get_tree().get_nodes_in_group("infected").is_empty():
			pending_level_path = "res://levels/game_over.tscn"
		else:
			var no_neutrals_left = get_tree().get_nodes_in_group("neutrals").is_empty()
			if no_neutrals_left:
				pending_level_path = next_level_path if next_level_path else "res://levels/game_completed.tscn"


func _update_input() -> void:
	if !pending_level_path and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func _update_timer(delta: float) -> void:
	if !pending_level_path:
		level_timer += delta
		
	if timer_label:
		var timer_total_secs : int = floor(level_timer)
		var timer_total_ms: int = floor(level_timer * 1000)
		var timer_ms_part: int = timer_total_ms % 1000
		var timer_secs_part = timer_total_secs % 60
		var timer_mins_part = timer_total_secs / 60
		timer_label.text = "%02d:%02d:%02d" % [timer_mins_part, timer_secs_part, timer_ms_part/10]
		
func _process(delta: float) -> void:
	_update_game_over(delta)
	_update_input()
	_update_timer(delta)
