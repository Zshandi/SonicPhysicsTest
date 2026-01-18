extends RefCounted

var _num_to_track: int
var _max_deviation: float

var current_values: Array[float]

func _init(num_to_track: int = 2, max_deviation: float = INF) -> void:
	_num_to_track = num_to_track
	_max_deviation = max_deviation

func process_value(value: float) -> void:
	current_values.push_back(value)
	if len(current_values) > _num_to_track:
		# Could be optimized, but only a constant size so shouldn't matter
		current_values.pop_front()

	# Reverse traverse the array skipping the last element
	var i = len(current_values) - 2
	while i >= 0:
		if abs(value - current_values[i]) > _max_deviation:
			# This is okay since we're reverse traversing the array,
			#  so only indices above will be affected
			current_values.remove_at(i)
		i -= 1

func get_current_average() -> float:
	var sum: float = 0
	for value in current_values:
		sum += value
	return sum / len(current_values)