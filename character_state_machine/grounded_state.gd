extends State
class_name GroundedState

func _init(character: Character, name: String = ""):
	super._init(character, "Air" + name)

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)

	if should_fall() and not ch.has_control_lock():
		ch.start_control_lock()

# Called when the state is transitioned to from another state
func _state_enter(delta: float, previous_state: State) -> void:
	super._state_enter(delta, previous_state)

	if not previous_state is GroundedState:
		update_ground_angle()
		var dot = ch.velocity.dot(Vector2.RIGHT.rotated(ch.ground_angle_rad))
		ch.ground_speed = ch.velocity.length() * sign(dot)
		

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	ch.count_control_lock(delta)

	super._physics_process(delta)

	update_ground_angle()
	ch.update_rotation_for_ground_angle()
	ch.snap_downward()

	if not is_ground_angle_on_ceiling():
		ch.ground_speed -= _get_slope_factor() * delta * sin(ch.ground_angle_rad)
	
	if should_slip() and not ch.has_control_lock():
		ch.ground_speed += ch.slip_speed_reduction * get_slope_dir()
		ch.start_control_lock()
	
	ch.velocity.x = ch.ground_speed * cos(ch.ground_angle_rad)
	ch.velocity.y = ch.ground_speed * -sin(ch.ground_angle_rad)
	

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	ch.facing_dir_scale = ch.get_input_left_right()
	ch.sprite.play("standing")

func update_ground_angle() -> void:
	var total_normal = Vector2.ZERO
	var total_normal_count = 0
	for sensor in ch.ground_sensors:
		if sensor.is_colliding():
			total_normal += sensor.get_collision_normal()
			total_normal_count += 1
	
	if total_normal_count > 0:
		var avg_normal = total_normal / total_normal_count
		ch.ground_angle = rad_to_deg(avg_normal.angle_to(Vector2.UP))
		if ch.ground_angle < 0:
			ch.ground_angle += 360

func is_ground_angle_on_ceiling() -> bool:
	return ch.ground_angle_within(ch.ceiling_min_angle)

func is_ground_angle_on_floor() -> bool:
	return not ch.ground_angle_within(ch.floor_max_angle)

func is_ground_angle_on_wall() -> bool:
	return not is_ground_angle_on_ceiling() and \
		   not is_ground_angle_on_floor()

func _get_slope_factor() -> float:
	return ch.slope_factor_normal

func get_slope_dir():
	return -1 if ch.ground_angle < 180 else 1

func should_slip() -> bool:
	var movement_dir = ch.get_input_left_right()
	var slip_conditions = abs(ch.ground_speed) < ch.slip_max_speed and ch.ground_angle_within(ch.slip_min_angle)
	var going_uphill = sign(movement_dir) != sign(get_slope_dir()) or movement_dir == 0
	return slip_conditions and (going_uphill or is_ground_angle_on_ceiling())

func should_fall() -> bool:
	return should_slip() and ch.ground_angle_within(ch.fall_min_angle)