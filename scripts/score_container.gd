extends Control

@export var score_value : Label
@export var cell_count_value : Label
@export var time_taken_value : Label

func _ready() -> void:
	if score_value:
		score_value.text = "%s" % GameProgression.get_total_score()
	if cell_count_value:
		cell_count_value.text = "%s" % GameProgression.get_total_count()
	if time_taken_value:
		# TODO deduplicate code
		var total_time = GameProgression.get_total_time_taken()
		var timer_total_secs : int = floor(total_time)
		var timer_total_ms: int = floor(total_time * 1000)
		var timer_ms_part: int = timer_total_ms % 1000
		var timer_secs_part = timer_total_secs % 60
		var timer_mins_part = timer_total_secs / 60
		time_taken_value.text = "%02d:%02d:%02d" % [timer_mins_part, timer_secs_part, timer_ms_part/10]
	
