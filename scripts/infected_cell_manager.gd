extends Node

@export var move_thrust = 1000.0
@export var decay_rate = 0.0 # EXPERIMENTAL - for a timed mode
@export var decay_min_size = 10.0
@export var last_hit_cell_cooldown = 1.0

var input_move : Vector2
var controlled_cell : Cell
var last_hit_cell : Cell
var last_hit_cell_cooldown_timer = 0.0
var player_camera : Camera2D

# ONLY used for initial controlled for now - maybe just remove and set that via level data?
func _update_controlled_cell_largest() -> void:
	var all_infected = get_tree().get_nodes_in_group("infected")
	var largest_cell : Cell
	var largest_size : float = 0.0
	
	for infected in all_infected:
		var cell = infected as Cell
		if cell:
			var this_size = cell.get_size()
			if this_size > largest_size:
				largest_size = this_size
				largest_cell = cell # TOOD handle tie (maintain current)

	set_controlled_cell(largest_cell)

func _update_controlled_cell_last_hit(delta: float) -> void:
	if last_hit_cell_cooldown_timer > 0.0:
		last_hit_cell_cooldown_timer -= delta
		return

	if controlled_cell == null:
		_update_controlled_cell_largest()
		return

	if last_hit_cell_cooldown_timer > 0.0:
		return
	
	last_hit_cell_cooldown_timer = 0.0

	# Naive implementation: transfer control over to the first valid collided infected cell
	# we could take into account speed but the cooldown may be enough.
	var all_infected = get_tree().get_nodes_in_group("infected")
	var found_controlled_cell = false
	for node in all_infected:
		var infected_cell = node as Cell
		# a "pending destroy" cell may have size 0
		if infected_cell and infected_cell.size > 0 and infected_cell == controlled_cell:
			found_controlled_cell = true
			var collided_infected_cell : Cell
			for collided_cell in infected_cell.collided_cells:
				if collided_cell.is_in_group("infected"):
					collided_infected_cell = collided_cell
					break
	
			if collided_infected_cell:
				set_controlled_cell(collided_infected_cell)
				last_hit_cell_cooldown_timer = last_hit_cell_cooldown
				break
	
	# No valid controlled cell for this rule, possibly because it was destroyed.
	if !found_controlled_cell:
		_update_controlled_cell_largest()

func _init_player_camera(controlled_cell : Cell):
	assert(controlled_cell)
	player_camera = controlled_cell.get_node("PlayerCamera")

func set_controlled_cell(new_controlled_cell : Cell):
	if new_controlled_cell == controlled_cell:
		return

	# The controlled cell is the largest cell, if any.
	# Update it and the AI states if it's changed.
	if controlled_cell:
		controlled_cell.ai_state = Cell.CELL_AI_STATE.FOLLOWING
	if new_controlled_cell:
		new_controlled_cell.ai_state = Cell.CELL_AI_STATE.NONE
	# Move camera over to new cell if applicable
	# Note the new controlled cell can be null if none left; move to root in this case.
	if player_camera.get_parent() != new_controlled_cell:
		if new_controlled_cell:
			player_camera.reparent(new_controlled_cell, false)
		else:
			player_camera.reparent(get_tree().current_scene)
	
	# FINALLY update current control cell
	controlled_cell = new_controlled_cell

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
				cell_thrust = to_leader_normalised * infected_leader_attraction_thrust
		cell.ai_thrust = cell_thrust
		

func _update_input() -> void:
	input_move = Vector2.ZERO
	input_move.x += Input.get_action_strength("move_right")
	input_move.x -= Input.get_action_strength("move_left")
	input_move.y -= Input.get_action_strength("move_up")
	input_move.y += Input.get_action_strength("move_down")


func _update_infected_decay(delta: float) -> void:
	var all_infected = get_tree().get_nodes_in_group("infected")
	for infected in all_infected:
		# Decay over time but note we may have lost size for other reasons
		# NOTE now used only for deleting dead cells; maybe delete the decay part
		if infected.size > decay_min_size:
			var new_size = infected.size - delta * decay_rate
			infected.size = max(decay_min_size, new_size)
		if infected.size <= 0:
			infected.queue_free()

func _update_game_over() -> void:
	if controlled_cell == null:
		get_tree().change_scene_to_file("res://levels/game_over.tscn")
	elif (get_tree().get_nodes_in_group("neutrals").is_empty() and 
		  get_tree().get_nodes_in_group("enemies").is_empty()):
		# TODO next level once we have multiple levels
		get_tree().change_scene_to_file("res://levels/game_completed.tscn")

func _ready() -> void:
	var initial_infected_cells = get_tree().get_nodes_in_group("infected")
	assert(!initial_infected_cells.is_empty(), "No viable infected cell to make the player-controlled cell!")
	_init_player_camera(initial_infected_cells[0])
	set_controlled_cell(initial_infected_cells[0])

func _process(delta: float) -> void:
	_update_controlled_cell_last_hit(delta)
	_update_follow_cells()
	_update_input()
	_update_infected_decay(delta)
	_update_game_over()

func _physics_process(_delta: float) -> void:
	if controlled_cell and !input_move.is_zero_approx():
		var thrust = input_move * move_thrust
		controlled_cell.apply_central_force(thrust)
