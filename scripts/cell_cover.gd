extends Area2D

@export var fade_out_seconds = 2.0

var fade_out_timer = 0.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("infected"):
		fade_out_timer = fade_out_seconds
		body_entered.disconnect(_on_body_entered)
	

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if fade_out_timer > 0.0:
		fade_out_timer -= delta
		var new_colour : Color = $Polygon2D.color
		new_colour.a = lerpf(0.0, 1.0, fade_out_timer / fade_out_seconds)
		$Polygon2D.set_color(new_colour)
