extends Node

@export var infect_absorb_time_period = 0.5
@export var infect_bounce_min_size = 10.0
@export var infect_bounce_energy_loss = 5.0
@export var infect_bounce_impulse = 1000.0
@export var infect_fixed_energy_loss = 10.0
@export var infect_destruction_bonus_energy = 100.0
@export var allow_self_destruct = false
@export_range(0.0, 1.0) var infect_bounce_ratio = 0.3
@export_range(0.0, 1.0) var infect_energy_ratio = 0.6

func _process_infected_on_neutral_collision(infected_cell : Cell, neutral_cell : Cell):
	var infect_energy = infected_cell.size - infect_fixed_energy_loss
	var self_destruct = allow_self_destruct and infect_energy < neutral_cell.size
	if self_destruct:
		infect_energy += infect_destruction_bonus_energy
	var successful_infect = infect_energy >= neutral_cell.size
	
	var total_energy = infect_energy + neutral_cell.size
	
	var infected_new_size = infected_cell.size
	var infected_absorb_impulse = Vector2.ZERO
	var neutral_new_size = neutral_cell.size
	
	# Small infected cell hits larger uninfected cell -> infected cell is absorbed
	if self_destruct:
		infected_new_size = 0 # Manager will delete after doing cleanup (e.g. camera)
		neutral_new_size = max(infect_bounce_min_size, total_energy * (1.0-infect_energy_ratio))
	# Large infected cell hits smaller uninfected cell -> uninfected cell is infected
	elif successful_infect:
		infected_new_size = max(infect_bounce_min_size, total_energy * infect_energy_ratio)
		neutral_new_size = max(infect_bounce_min_size, total_energy * (1.0-infect_energy_ratio))
	# Small infected cell hits cell it can't convert -> take a small chunk of energy frokm each
	elif infected_cell.size > infect_bounce_min_size:
		infected_new_size = max(infect_bounce_min_size, infected_cell.size - infect_fixed_energy_loss * infect_bounce_ratio)
		neutral_new_size = max(infect_bounce_min_size, neutral_cell.size - infect_fixed_energy_loss * (1.0-infect_bounce_ratio))

		var away_direction = infected_cell.get_position() - neutral_cell.get_position()
		away_direction = Vector2.UP if away_direction.is_zero_approx() else away_direction.normalized()
		infected_absorb_impulse = away_direction * infect_bounce_impulse

	if infected_cell.size != infected_new_size:
		infected_cell.set_absorbing(infected_new_size, infect_absorb_time_period, infected_absorb_impulse)
	if neutral_cell.size != neutral_new_size:
		neutral_cell.set_absorbing(neutral_new_size, infect_absorb_time_period)
		
	

	# Cell sizes have been updated either way so update dependent values
	# NOTE now handled within cell code as we freeze and gradually change size
	#infected_cell.on_update_size()
	#neutral_cell.on_update_size()

	# Convert neutral to infected cell if it was a successful infect
	if successful_infect:
		neutral_cell.circle.set_color(infected_cell.circle.color)
		neutral_cell.ai_state = Cell.CELL_AI_STATE.FOLLOWING
		neutral_cell.remove_from_group("neutrals")
		neutral_cell.add_to_group("infected")

func _process_infected_on_infected_collision(infected_cell_1 : Cell, infected_cell_2 : Cell):
	return # just a test
	# take equal energy for now, regardless of who did the hit (could do by momentum here?)
	if infected_cell_1.size - infect_bounce_energy_loss >= infect_bounce_min_size:
		infected_cell_1.size -= infect_bounce_energy_loss
		infected_cell_1.on_update_size()
	if infected_cell_2.size - infect_bounce_energy_loss >= infect_bounce_min_size:
		infected_cell_2.size -= infect_bounce_energy_loss
		infected_cell_2.on_update_size()

func _process(_delta) -> void:
	# TODO avoid duplicate collisions
	var all_infected = get_tree().get_nodes_in_group("infected")
	var all_neutrals = get_tree().get_nodes_in_group("neutrals")
	for infected in all_infected:
		var infected_cell = infected as Cell
		if infected_cell:
			for collided_cell : Cell in infected_cell.collided_cells:
				if collided_cell.is_in_group("neutrals"):
					_process_infected_on_neutral_collision(infected_cell, collided_cell)
				elif collided_cell.is_in_group("infected"):
					_process_infected_on_infected_collision(infected_cell, collided_cell)
			infected_cell.collided_cells.clear()

	# just cleanup - note the group may have changed
	for neutral in all_neutrals:
		var cell = neutral as Cell
		if cell:
			cell.collided_cells.clear()
