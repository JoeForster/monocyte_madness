@tool

extends RigidBody2D
class_name Cell

enum CELL_AI_STATE
{
	NONE,
	PAUSED,
	WANDERING,
	FOLLOWING
}

@export var initial_size : float = 100.0 :
	set(value):
		initial_size = value
#@export var initial_state : NEUTRAL_AI_STATE = NEUTRAL_AI_STATE.NONE
@export var circle : Circle2D
@export var collision : CollisionShape2D

# TODO rename to radius? Separate concept of energy from radius?
var size : float
var collided_cells : Array[Cell]

var ai_state = CELL_AI_STATE.NONE
var ai_state_timer = 0.0
var ai_thrust = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if ai_state == CELL_AI_STATE.WANDERING || ai_state == CELL_AI_STATE.FOLLOWING:
		apply_central_force(ai_thrust)

func on_update_size():
	if Engine.is_editor_hint():
		size = initial_size
	var circle_shape = collision.shape as CircleShape2D
	if circle_shape:
		circle_shape.radius = size
	circle.radius = size
	circle.queue_redraw()

func get_size() -> float:
	return size

func _on_body_entered(body: Node):
	var cell = body as Cell
	if cell:
		print("%s HIT %s" % [name, cell.name])
		collided_cells.push_back(cell)

func _ready() -> void:
	size = initial_size
	#ai_state = initial_state
	body_entered.connect(_on_body_entered)	
	
func _process(_delta: float) -> void:
	# TEMP may not be necessary every frame
	on_update_size()
