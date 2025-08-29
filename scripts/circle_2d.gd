@tool

extends Node2D
class_name Circle2D

@export var color : Color = Color.WHITE :
	set(value):
		color = value
		queue_redraw()

@export var radius : float = 100.0 :
	set(value):
		radius = value
		queue_redraw()

@export var filled : bool = true
@export var width : float = -1.0

func _draw():
	if filled:
		draw_circle(Vector2.ZERO, radius, color, filled)
	else:
		draw_circle(Vector2.ZERO, radius, color, filled, width)

func set_color(new_color : Color):
	self.color = new_color
	queue_redraw()
