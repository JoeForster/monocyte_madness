extends Node

@export var move_thrust = 1000.0
@export var decay_rate = 0.0 # EXPERIMENTAL - for a timed mode
@export var decay_min_size = 10.0

var input_move : Vector2
var controlled_cell : Cell
var player_camera : Camera2D

func _update_infected_decay(delta: float) -> void:
	var all_infected = get_tree().get_nodes_in_group("infected")
	for infected in all_infected:
		var new_size = infected.size - delta * decay_rate
		infected.size = max(decay_min_size, new_size)
	
func _update_controlled_cell() -> void:
	var all_infected = get_tree().get_nodes_in_group("infected")
	var largest_cell : Cell
	var largest_size : float = -1.0
	
	for infected in all_infected:
		var cell = infected as Cell
		if cell:
			var this_size = cell.get_size()
			if this_size > largest_size:
				largest_size = this_size
				largest_cell = cell # TOOD handle tie (maintain current)

	# The controlled cell is the largest cell, if any.
	# Update it and the AI states if it's changed.
	if largest_cell != controlled_cell:
		if controlled_cell:
			controlled_cell.ai_state = Cell.CELL_AI_STATE.FOLLOWING
		if largest_cell:
			largest_cell.ai_state = Cell.CELL_AI_STATE.NONE

		controlled_cell = largest_cell
	

	# TODO handle death & smoother camera movement with spring arm of some kind
	# (probably need to keep camera under this manager's ownership)
	if player_camera == null:
		player_camera = largest_cell.get_node("PlayerCamera")
	elif !largest_cell.has_node("PlayerCamera"):
		player_camera.get_parent().remove_child(player_camera)
		player_camera.set_owner(largest_cell)
		largest_cell.add_child(player_camera)


@export var infected_leader_attraction_dist = 800.0
@export var infected_leader_attraction_thrust = 1200.0
@export var infected_separation_dist = 150.0
@export var infected_separation_repel = 400.0
@export var infected_alignment_turn_rate = 30.0 # NOT USED YET


func _update_follow_cells() -> void:
	if controlled_cell == null:
		return
	
	var all_infected = get_tree().get_nodes_in_group("infected")
	var leader_pos = controlled_cell.get_global_position()
	
	for infected in all_infected:
		var cell = infected as Cell
		if cell == controlled_cell || cell.ai_state != Cell.CELL_AI_STATE.FOLLOWING:
			continue
			
		var cell_pos = cell.get_global_position()
		var to_leader = leader_pos - cell_pos
		var dist_to_leader = to_leader.length()
		
		# Subtract radii so we measure distance from cell border not centre.
		dist_to_leader -= controlled_cell.size
		dist_to_leader -= cell.size
		# should only happen if we have collision or teleportation penetration
		if dist_to_leader < 0.0:
			dist_to_leader = 0.0
		
		
		var cell_thrust = Vector2.ZERO
		if dist_to_leader <= infected_leader_attraction_dist:
			var to_leader_normalised = Vector2.UP if to_leader.is_zero_approx() else to_leader.normalized()
			if dist_to_leader < infected_separation_dist:
				cell_thrust = -to_leader_normalised * infected_separation_repel
			else:
				# TODO alignment goes here
				cell_thrust = to_leader_normalised * infected_separation_repel
		cell.ai_thrust = cell_thrust
		

func _update_input() -> void:
	input_move = Vector2.ZERO
	input_move.x += Input.get_action_strength("move_right")
	input_move.x -= Input.get_action_strength("move_left")
	input_move.y -= Input.get_action_strength("move_up")
	input_move.y += Input.get_action_strength("move_down")

func _process(delta: float) -> void:
	_update_infected_decay(delta)
	_update_controlled_cell()
	_update_follow_cells()
	_update_input()

func _physics_process(_delta: float) -> void:
	if controlled_cell and !input_move.is_zero_approx():
		var thrust = input_move * move_thrust
		controlled_cell.apply_central_force(thrust)
