@tool

extends Polygon2D

@export var update_collision : bool = false :
	set(value):
		$"../CollisionPolygon2D".polygon = polygon
		update_collision = false
