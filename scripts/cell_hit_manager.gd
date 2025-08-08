extends Node

@export var infect_bounce_min_size = 10.0
@export var infect_bounce_energy_loss = 5.0
@export var infect_fixed_energy_loss = 20.0
@export_range(0.0, 1.0) var infect_bounce_ratio = 0.3
@export_range(0.0, 1.0) var infect_energy_ratio = 0.6

func _process_infected_on_neutral_collision(infected_cell : Cell, neutral_cell : Cell):
	# NON-DESTRUCTIVE rules here for now - can't die from these collisions.
	# If you hit a cell too big to infect, bounce and reduce its energy a bit.
	var successful_infect = infected_cell.size >= neutral_cell.size + infect_fixed_energy_loss
	if !successful_infect:
		infected_cell.size = max(infect_bounce_min_size, infected_cell.size - infect_fixed_energy_loss * infect_bounce_ratio)
		neutral_cell.size = max(infect_bounce_min_size, neutral_cell.size - infect_fixed_energy_loss * (1.0-infect_bounce_ratio))
	# If you hit a smaller cell, 
	else:
		infected_cell.size = max(infect_bounce_min_size, infected_cell.size - infect_fixed_energy_loss)
		var total_energy = infected_cell.size + neutral_cell.size
		infected_cell.size = max(infect_bounce_min_size, total_energy * infect_energy_ratio)
		neutral_cell.size = max(infect_bounce_min_size, total_energy * (1.0-infect_energy_ratio))
	
	# Size has been updated either way so update dependent values
	infected_cell.on_update_size()
	neutral_cell.on_update_size()

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
