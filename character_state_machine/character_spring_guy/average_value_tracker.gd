extends RefCounted
class_name AverageValueTracker

var _num_to_track: int
var _max_deviation: float

var current_normals: Array[Vector2]

func _init(num_to_track: int = 2, max_deviation: float = INF) -> void:
	_num_to_track = num_to_track
	_max_deviation = max_deviation

func reset() -> void:
	current_normals.clear()

func set_num_to_track(num_to_track: int) -> void:
	_num_to_track = num_to_track
	while len(current_normals) > _num_to_track:
		current_normals.pop_front()

func process_value(value: Vector2) -> void:
	current_normals.push_back(value)
	if len(current_normals) > _num_to_track:
		# Could be optimized, but only a constant size so shouldn't matter
		current_normals.pop_front()

	# Reverse traverse the array skipping the last element
	var i = len(current_normals) - 2
	while i >= 0:
		if abs(value.angle_to(current_normals[i])) > _max_deviation:
			# This is okay since we're reverse traversing the array,
			#  so only indices above will be affected
			current_normals.remove_at(i)
		i -= 1

func get_average_angle() -> float:
	DebugValues.debug("len(current_normals)", len(current_normals))
	DebugValues.debug("_num_to_track", _num_to_track)
	var sum: Vector2 = Vector2.ZERO
	for value in current_normals:
		sum += value
	if sum == Vector2.ZERO: return 0
	return Vector2.UP.angle_to(sum)