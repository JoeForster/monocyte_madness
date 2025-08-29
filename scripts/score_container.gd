extends Control

@export var score_value : Label
@export var cell_count_value : Label

func _ready() -> void:
	if score_value:
		score_value.text = "%s" % GameProgression.get_total_score()
	if cell_count_value:
		cell_count_value.text = "%s" % GameProgression.get_total_count()
	
