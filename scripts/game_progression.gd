extends Node

@export var score_size_multiplier = 10

class LevelResults:
	var num_infected_cells = 0
	var total_infected_size = 0.0
	var biggest_size = 0.0

var results : Array[LevelResults]

func add_level_results(num_infected_cells, total_infected_size, biggest_size):
	var new_results = LevelResults.new()
	new_results.num_infected_cells = num_infected_cells
	new_results.total_infected_size = total_infected_size
	new_results.biggest_size = biggest_size
	results.append(new_results)

func get_total_score() -> int:
	var total_score = 0.0
	for result in results:
		var size_score = result.total_infected_size * score_size_multiplier
		total_score += size_score
	return int(total_score) # round down the final total

func get_total_count() -> int:
	var total_count = 0
	for result in results:
		total_count += result.num_infected_cells
	return total_count
