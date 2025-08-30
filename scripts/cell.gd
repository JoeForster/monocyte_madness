@tool

extends RigidBody2D
class_name Cell

# TODO: only really used properly for neutral cells; needs tidy.
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
@export var marker_circle : Circle2D
@export var collision : CollisionShape2D
@export var damage_area : Area2D
@export var absorb_anim : AnimatedSprite2D

# TODO rename to radius? Separate concept of energy from radius?
var size : float
var collided_cells : Array[Cell]

var ai_state = CELL_AI_STATE.NONE
var ai_state_timer = 0.0
var ai_thrust = Vector2.ZERO

var _absorbing_timer = 0.0
var _absorbing_target_size : float
var _absorbing_size_change_per_sec : float
var _absorbing_impulse_to_apply : Vector2

func set_absorbing(target_size : float, time_period : float, impulse_after : Vector2 = Vector2.ZERO):
	assert(time_period > 0.0)
	assert(target_size >= 0.0)
	_absorbing_target_size = target_size
	_absorbing_timer = time_period
	_absorbing_size_change_per_sec = (target_size - size) / time_period
	_absorbing_impulse_to_apply = impulse_after
	freeze = true
	absorb_anim.visible = true
	
func on_update_size():
	if Engine.is_editor_hint():
		size = initial_size
	var circle_shape = collision.shape as CircleShape2D
	if circle_shape:
		circle_shape.radius = size
	circle.radius = size
	circle.visible = size > 0
	circle.queue_redraw()
	marker_circle.radius = size
	marker_circle.queue_redraw()
	
func set_is_controlled(is_controlled : bool) -> void:
	if marker_circle:
		marker_circle.visible = is_controlled

func get_size() -> float:
	return size

func _on_body_entered(body: Node):
	var cell = body as Cell
	if cell:
		collided_cells.push_back(cell)

func _ready() -> void:
	size = initial_size
	#ai_state = initial_state
	body_entered.connect(_on_body_entered)	

func _process(delta: float) -> void:
	# TODO remove temp check to shut up editor spam due to this script running in tool mode
	if !Engine.is_editor_hint():
		if _absorbing_timer > 0.0:
			_absorbing_timer -= delta
			if _absorbing_timer <= 0.0:
				size = _absorbing_target_size
				freeze = false
				absorb_anim.visible = false
				apply_central_impulse(_absorbing_impulse_to_apply)
			else:
				size += _absorbing_size_change_per_sec * delta
	# TEMP NOT NECESSARY every frame but needs testing without
	on_update_size()

func _physics_process(_delta: float) -> void:
	if ai_state == CELL_AI_STATE.WANDERING || ai_state == CELL_AI_STATE.FOLLOWING:
		apply_central_force(ai_thrust)
