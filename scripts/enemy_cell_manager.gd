extends Node

# Initial idea: from spawn_time_start to spawn_time_end we scale the
# other parameters linearly to give a gradual increase of difficulty.
# (could use a Curve for each parameter to give even more control?)

@export var spawn_time_start = 5.0
@export var spawn_time_end = 120.0
@export var spawn_count_start = 1
@export var spawn_count_end = 3
@export var move_thrust_start = 1000.0
@export var move_thrust_end = 2000.0 
@export var move_damp_start = 3.0
@export var move_damp_end = 2.0
@export_range(0, 90, 0.1, "radians_as_degrees") var min_angle_to_player_start: float = deg_to_rad(20)
@export_range(0, 90, 0.1, "radians_as_degrees") var max_angle_to_player_start: float = deg_to_rad(45)
@export_range(0, 90, 0.1, "radians_as_degrees") var min_angle_to_player_end: float = deg_to_rad(0)
@export_range(0, 90, 0.1, "radians_as_degrees") var max_angle_to_player_end: float = deg_to_rad(5)


@export var actors_parent : Node
@export var spawn_path : Path2D
@export var bounds_area : Area2D
@export var spawn_enemy_scene : PackedScene

@export var enemy_overlap_damage : float = 20.0
@export var kill_size = 10.0

var difficulty_timer = 0.0
var current_spawn_count = 0
var current_move_thrust = move_thrust_start
var current_move_damp = move_damp_start
var current_min_angle_to_player = min_angle_to_player_start
var current_max_angle_to_player = max_angle_to_player_start

var current_enemies_spawned : Array[Cell]

func _process_difficulty(delta: float) -> void:
	difficulty_timer += delta
	if difficulty_timer > spawn_time_end:
		difficulty_timer = spawn_time_end
	if difficulty_timer > spawn_time_start:
		var weight = (difficulty_timer - spawn_time_start) / (spawn_time_end / spawn_time_start)
		current_spawn_count = int(lerp(spawn_count_start, spawn_count_end, weight))
		current_move_thrust = lerpf(move_thrust_start, move_thrust_end, weight)
		current_move_damp = lerpf(move_damp_start, move_damp_end, weight)
		current_min_angle_to_player = lerp_angle(min_angle_to_player_start, min_angle_to_player_end, weight)
		current_max_angle_to_player = lerp_angle(max_angle_to_player_start, max_angle_to_player_end, weight)
	
func _enemy_still_valid(cell : Cell) -> bool:
	return cell != null && cell.is_in_group("enemies") && !bounds_area.overlaps_body(cell)

func _process_spawning() -> void:
	if actors_parent == null || spawn_path == null || spawn_enemy_scene == null:
		return
	
	# First remove any enemy cells no longer valid (unspawning)
	# Here we assume only this manager can create them, so we don't have to call get_nodes_in_group.
	var new_valid_enemies : Array[Cell]
	for enemy in current_enemies_spawned:
		if _enemy_still_valid(enemy):
			new_valid_enemies.push_back(enemy)
		elif enemy != null:
			enemy.queue_free() # Exists but needs to despawn based on rules in _enemy_still_valid

	if new_valid_enemies != current_enemies_spawned:
		current_enemies_spawned = new_valid_enemies
	
	while current_enemies_spawned.size() < current_spawn_count:
		var sample_dist = randf_range(0.0, spawn_path.curve.get_baked_length())
		var spawn_pos = spawn_path.curve.sample_baked(sample_dist)
		var spawn_pos_global = spawn_path.to_global(spawn_pos)
		var spawned_enemy : Cell = spawn_enemy_scene.instantiate()
		assert(spawned_enemy)
		actors_parent.add_child(spawned_enemy)
		spawned_enemy.set_owner(actors_parent)
		spawned_enemy.set_global_position(spawn_pos_global)
		# TODO get controlled player?
		spawned_enemy.ai_thrust = Vector2.ZERO
		
		# Just fly at the player and we'll despawn when we leave bounds on the other side.
		var all_infected = get_tree().get_nodes_in_group("infected")
		if !all_infected.is_empty():
			var random_infected : Cell = all_infected.pick_random()
			assert(random_infected)
			var initial_direction = (random_infected.get_position() - spawned_enemy.get_position()).normalized()
			var random_turn = lerp_angle(current_min_angle_to_player, current_max_angle_to_player, randf())
			if randi() % 2 == 0:
				random_turn *= -1.0
			print("random_turn %.2f" % rad_to_deg(random_turn))
			initial_direction.rotated(random_turn)
			spawned_enemy.ai_thrust = initial_direction * current_move_thrust
			spawned_enemy.linear_damp = current_move_damp
			# use same state as neutrals, but just means it'll apply ai_thrust constantly.
			spawned_enemy.ai_state = Cell.CELL_AI_STATE.WANDERING

		current_enemies_spawned.push_back(spawned_enemy)

func _process_damage(delta: float) -> void:
	for enemy in current_enemies_spawned:
		for body in enemy.damage_area.get_overlapping_bodies():
			var overlap_cell = body as Cell
			if overlap_cell and overlap_cell.is_in_group("infected"):
				overlap_cell.size -= enemy_overlap_damage
				# hack to get fixed damage once per cell
				enemy.damage_area.process_mode = Node.PROCESS_MODE_DISABLED
				
				overlap_cell.on_update_size()
				if overlap_cell.size <= kill_size:
					overlap_cell.queue_free()
				
func _process(delta: float) -> void:
	# Check all infected cells and determine largest
	#var all_enemies = get_tree().get_nodes_in_group("enemies")
	_process_difficulty(delta)
	_process_spawning()
	_process_damage(delta)
	
