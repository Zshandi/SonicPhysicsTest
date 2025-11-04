extends State
class_name GroundedStateBase

var GROUNDED_DEBUG := "GROUNDED"
var SLIP_DEBUG := "SLIP"
var JITTER_DEBUG := "JITTER"

func _init(character: Character, name: String = ""):
	super._init(character, "Grounded" + name)
	DebugValues.category(GROUNDED_DEBUG, KEY_G)
	DebugValues.category(SLIP_DEBUG, KEY_S)
	DebugValues.category(JITTER_DEBUG, KEY_J)

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)

	if should_fall() and should_slip() and not ch.has_control_lock():
		ch.start_control_lock()

# Called when the state is transitioned to from another state
func _state_enter(delta: float, previous_state: State) -> void:
	super._state_enter(delta, previous_state)
	prev_ground_angle_normals = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]

	if not previous_state is GroundedStateBase:
		if ch.is_on_floor():
			# We landed on the floor
			update_ground_angle()
		else:
			# We landed on the wall or ceiling
			var angle_rad = get_last_slide_collision_angle_rad()
			assert(not is_nan(angle_rad))
			if not is_nan(angle_rad):
				ch.ground_angle_rad = angle_rad
				ch.update_rotation_for_ground_angle()
				ch.snap_downward(15)

		var ground_speed = get_ground_speed_for(ch.velocity, ch.ground_angle_rad)
		ch.ground_speed = ground_speed
		
# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	ch.count_control_lock(delta)

	update_ground_angle()
	ch.update_rotation_for_ground_angle()
	ch.snap_downward(15)

	DebugValues.debug("ground_angle", ch.ground_angle, GROUNDED_DEBUG)
	DebugValues.debug("ground_speed", ch.ground_speed / ch.speed_scale, GROUNDED_DEBUG)
	DebugValues.debug("effective_slope_factor", get_effective_slope_factor(), GROUNDED_DEBUG)
	DebugValues.debug("does_slope_factor_apply", does_slope_factor_apply(), GROUNDED_DEBUG)
	if ch.get_last_slide_collision() != null:
		var angle = get_last_slide_collision_angle_rad()
		DebugValues.debug("last_collision_angle", angle, GROUNDED_DEBUG)
	else:
		DebugValues.debug("last_collision_angle", "null", GROUNDED_DEBUG)
	if not is_ground_angle_on_ceiling() and does_slope_factor_apply():
			ch.ground_speed -= get_effective_slope_factor() * delta
	
	if should_slip() and not ch.has_control_lock():
		ch.ground_speed += ch.slip_speed_reduction * get_slope_dir()
		ch.start_control_lock()
	
	_physics_process_ground_controls(delta)

	ch.velocity.x = ch.ground_speed * cos(ch.ground_angle_rad)
	ch.velocity.y = ch.ground_speed * -sin(ch.ground_angle_rad)

func _physics_process_ground_controls(_delta: float):
	pass

func _get_slope_factor() -> float:
	return ch.slope_factor_normal

func _get_friction() -> float:
	return ch.friction_speed

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	ch.facing_dir_scale = ch.get_input_left_right()
	ch.sprite.play("standing")

func get_effective_slope_factor() -> float:
	return _get_slope_factor() * sin(ch.ground_angle_rad)

func does_slope_factor_apply() -> bool:
	return abs(get_effective_slope_factor()) > _get_friction()

func get_reasonable_sensors(sensors: Array[Sensor], variance: float = 2) -> Array[Sensor]:
	# Only consider colliding sensors
	var colliding_sensors: Array[Sensor] = sensors.filter(func(sensor): return sensor.is_colliding())
	if len(colliding_sensors) == 0: return []

	# Arbitrarily choose the first normal to compare the others to for variance
	# Note that this has no impact or implication on the average, which will
	#  be calculated as the average difference from this normal
	var first_normal := colliding_sensors[0].get_collision_normal()

	var angles_from_first: Array = colliding_sensors.map(func(sensor):
		return sensor.get_collision_normal().angle_to(first_normal)
		)
	
	var acceptable_angle_range := get_acceptable_range(angles_from_first, variance)
	var min_angle = min(acceptable_angle_range[0], acceptable_angle_range[1])
	var max_angle = max(acceptable_angle_range[0], acceptable_angle_range[1])

	var acceptable_sensors: Array[Sensor] = sensors.filter(func(sensor):
		var angle=sensor.get_collision_normal().angle_to(first_normal)
		return angle >= min_angle and angle <= max_angle
		)
	
	return acceptable_sensors

func get_acceptable_range(dataset: Array, variance: float = 2) -> Array[float]:
	var sum := func(total, current): return total + current
	# Step one: find average / mean
	var average: float = dataset.reduce(sum, 0) / len(dataset)

	# Step two: Get the square of the difference from the mean
	var squared_distances := dataset.map(func(value): return (value - average) * (value - average))

	# Step three: Sum and divide by total data points
	var standard_deviation: float = squared_distances.reduce(sum, 0) / len(dataset)
	
	# Step four: Subtract and add the SD (scaled by variance) to the average to get the range
	return [average - standard_deviation * variance, average + standard_deviation * variance]


func update_ground_angle() -> void:
	var total_normal = Vector2.ZERO
	var total_normal_count = 0
	# The get_reasonable_sensors deals with removing outliers in case of nearly 90 degree angles
	for sensor in get_reasonable_sensors(ch.ground_sensors, 15):
		total_normal += sensor.get_collision_normal()
		total_normal_count += 1
	if total_normal_count > 0:
		var avg_normal = total_normal / total_normal_count
		ch.ground_angle = rad_to_deg(avg_normal.angle_to(Vector2.UP))
		if ch.ground_angle < 0:
			ch.ground_angle += 360
		reduce_ground_angle_jitter()

var prev_ground_angle_normals: Array[Vector2]
func reduce_ground_angle_jitter():
	var current_ground_angle_normal := Vector2.UP.rotated(ch.ground_angle_rad)
	prev_ground_angle_normals.push_back(current_ground_angle_normal)
	
	var current_angle_change: float = prev_ground_angle_normals[-1].angle_to(prev_ground_angle_normals[ - 2])
	var prev_angle_change: float = prev_ground_angle_normals[-2].angle_to(prev_ground_angle_normals[ - 3])
	
	var current_angle := ch.ground_angle
	DebugValues.debug("current_angle_change", current_angle_change, JITTER_DEBUG)
	DebugValues.debug("prev_angle_change", prev_angle_change, JITTER_DEBUG)
	DebugValues.debug("unchanged ground_angle", current_angle, JITTER_DEBUG)
	DebugValues.debug("change to ground_angle", 0, JITTER_DEBUG)

	if sign(current_angle_change) != sign(prev_angle_change):
		var sum: Vector2 = prev_ground_angle_normals.reduce(func(accum, current): return accum + current, Vector2.ZERO)
		var avg_normal := sum / len(prev_ground_angle_normals)
		ch.ground_angle_rad = Vector2.UP.angle_to(avg_normal)
		DebugValues.debug("change to ground_angle", rad_to_deg(abs(avg_normal.angle_to(current_ground_angle_normal))), JITTER_DEBUG)
	prev_ground_angle_normals.pop_front()

func is_ground_angle_on_ceiling() -> bool:
	return ground_angle_within(ch.ceiling_min_angle, ch.ground_angle)

func is_ground_angle_on_floor() -> bool:
	return not ground_angle_within(ch.floor_max_angle, ch.ground_angle)

func is_ground_angle_on_wall() -> bool:
	return not is_ground_angle_on_ceiling() and \
		   not is_ground_angle_on_floor()

func get_slope_dir():
	return -1 if ch.ground_angle < 180 else 1

func should_land_on_wall_or_ceiling() -> bool:
	# Check they're on the wall or ceiling
	if not (ch.is_on_ceiling() or ch.is_on_wall()):
		return false
	
	if ch.velocity.y > 0: return false
	
	var potential_ground_angle_rad := get_last_slide_collision_angle_rad()
	if is_nan(potential_ground_angle_rad): return false
	
	var potential_ground_speed := get_ground_speed_for(ch.velocity, potential_ground_angle_rad)

	return not check_slip_conditions_for(potential_ground_speed, ch.slip_max_speed * 1.5, rad_to_deg(potential_ground_angle_rad))

func get_ground_speed_for(velocity: Vector2, ground_angle_rad: float) -> float:
	var ground_right_dir = Vector2.RIGHT.rotated(-ground_angle_rad)
	var dot = velocity.dot(ground_right_dir)
	var result = velocity.length() * sign(dot)
	return result

func check_slip_conditions_for(ground_speed: float, slip_max_speed: float, ground_angle: float) -> bool:
	return abs(ground_speed) < slip_max_speed and ground_angle_within(ch.slip_min_angle, ground_angle)

func should_slip() -> bool:
	var movement_dir = ch.get_input_left_right()
	DebugValues.debug("movement_dir", sin(movement_dir), SLIP_DEBUG)
	var slip_conditions = check_slip_conditions_for(ch.ground_speed, ch.slip_max_speed, ch.ground_angle)
	if not slip_conditions:
		return false
	DebugValues.debug("slip_conditions", slip_conditions, SLIP_DEBUG)
	DebugValues.debug("  abs(ch.ground_speed)", abs(ch.ground_speed), SLIP_DEBUG)
	DebugValues.debug("  < ch.slip_max_speed", abs(ch.slip_max_speed), SLIP_DEBUG)
	DebugValues.debug("  and ground_angle_within(ch.slip_min_angle)", ground_angle_within(ch.slip_min_angle, ch.ground_angle), SLIP_DEBUG)
	var going_uphill = sign(movement_dir) != sign(get_slope_dir()) or movement_dir == 0
	DebugValues.debug("sign(movement_dir) != sign(get_slope_dir()) or movement_dir == 0", going_uphill, SLIP_DEBUG)
	DebugValues.debug("  movement_dir", movement_dir, SLIP_DEBUG)
	DebugValues.debug("  get_slope_dir()", get_slope_dir(), SLIP_DEBUG)
	if not (going_uphill or is_ground_angle_on_ceiling()):
		return false
	check_slip_conditions_for(ch.ground_speed, ch.slip_max_speed, ch.ground_angle)
	return true

func should_fall() -> bool:
	if should_slip() and ground_angle_within(ch.fall_min_angle, ch.ground_angle):
		return true
	
	if ch.is_on_floor(): return false

	for sensor in ch.ground_sensors:
		if sensor.is_colliding() and sensor.get_collision_depth() < 15:
			return false
	
	return true

# direction should be -1 for deceleration or 1 for acceleration
func apply_acceleration(delta: float, direction: int, acceleration: float, top_speed: float) -> void:
	# If accelerating, pre-check for surpassing the speed,
	#  this way pressing in the direction of movement will never slow you down
	if direction == 1 && abs(ch.ground_speed) >= top_speed: return

	var movement_dir = ch.get_input_left_right()
	if movement_dir != 0 and (sign(movement_dir * direction) == sign(ch.ground_speed) or \
		(direction == 1 and ch.ground_speed == 0)):
		ch.ground_speed += acceleration * delta * movement_dir
		ch.ground_speed = clamp(ch.ground_speed, -top_speed, top_speed)
		DebugValues.debug("acceleration " + str(direction), acceleration * delta * movement_dir, GROUNDED_DEBUG)
	else:
		DebugValues.debug("acceleration " + str(direction), 0, GROUNDED_DEBUG)

# direction should be -1 for deceleration or 1 for acceleration
func apply_friction(delta: float) -> void:
	var ground_speed_sign = sign(ch.ground_speed)
	var total_friction = ground_speed_sign * _get_friction() * delta
	ch.ground_speed -= total_friction
	if ground_speed_sign != sign(ch.ground_speed):
		# We stopped, don't jitter
		ch.ground_speed = 0

func ground_angle_within(min_angle: float, ground_angle: float) -> bool:
	var max_angle := 360 - min_angle
	return ground_angle >= min_angle and ground_angle <= max_angle

func get_last_slide_collision_angle_rad() -> float:
	if ch.get_last_slide_collision() == null: return NAN
	var angle = fmod(ch.get_last_slide_collision().get_normal().angle_to(Vector2.UP), 2 * PI)
	if angle < 0: angle += 2 * PI
	return angle
