@tool
extends Resource
class_name InputMinMax

const range_min := 0.0
const range_max := 2.0

# TODO: This could be done with a dynamic range (i.e. passed in constructor),
#  however this requires a bunch of extra boiler plate code overriding _get_property_list etc.
@export_range(range_min, range_max)
var min_value: float = 1:
	set(value):
		if value > max_value:
			value = max_value
		min_value = value
@export_range(range_min, range_max)
var max_value: float = 1:
	set(value):
		if value < min_value:
			value = min_value
		max_value = value

func generate_value() -> float:
	return randf_range(min_value, max_value)