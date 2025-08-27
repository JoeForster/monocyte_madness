extends Control

@export var press_delay_secs = 2.0
@export var next_scene : String
@export var to_show_after_delay : Control

var press_delay_timer = press_delay_secs

func _process(delta: float) -> void:
	if press_delay_timer > 0.0:
		press_delay_timer -= delta
	else:
		if to_show_after_delay:
			to_show_after_delay.visible = true
		if Input.is_anything_pressed() :
			get_tree().change_scene_to_file(next_scene)
