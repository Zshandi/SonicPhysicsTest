extends CharacterBody2D
class_name Character

# Constant factors

var framerate := 60
var scaling_factor := 1.5
var speed_scale := framerate * scaling_factor
var acceleration_scale := framerate * framerate * scaling_factor

# Settings variables

var top_speed := 6 * speed_scale

var jump_speed := 6.5 * speed_scale
var jump_stop_speed := 4 * speed_scale

var acceleration_speed := 0.046875 * acceleration_scale
var deceleration_speed := 0.5 * acceleration_scale
var friction_speed := 0.046875 * acceleration_scale

var roll_friction_speed := 0.0234375 * acceleration_scale
var roll_deceleration_speed := 0.125 * acceleration_scale
var top_speed_rolling := 16 * speed_scale
var min_rolling_start_speed := 1 * speed_scale

var slope_factor_normal := 0.125 * acceleration_scale
var slope_factor_rollup := 0.078125 * acceleration_scale
var slope_factor_rolldown := 0.3125 * acceleration_scale

var air_acceleration := 0.09375 * acceleration_scale

var gravity_force := 0.21875 * acceleration_scale
var top_falling_speed := 16 * speed_scale

var ground_distance := 5

var wall_min_angle := 46
var ceiling_min_angle := 135

var slip_max_speed := 2.5 * speed_scale
var slip_speed_reduction := 0.5 * speed_scale
var slip_min_angle := 35
var fall_min_angle := 69
var control_lock_start := 0.5

# State variables

var ground_speed := 0.0

var ground_angle_rad := 0.0
var ground_angle := 0.0:
	set(value):
		ground_angle_rad = deg_to_rad(value)
	get:
		return rad_to_deg(ground_angle_rad)

var facing_dir_scale := 1.0:
	set(value):
		if value != 0:
			facing_dir_scale = sign(value)
			%CharacterSprite.scale.x = abs(%CharacterSprite.scale.x) * facing_dir_scale

var control_lock_timer := 0.0

var lock_transition_frames := 0

@onready
var sprite: AnimatedSprite2D = %CharacterSprite

@onready
var ground_sensors := [%GroundSensor1, %GroundSensor2, %GroundSensor3]

var current_state: State

var falling_state := FallingState.new(self)
var idle_state := IdleState.new(self)
var running_state := RunningState.new(self)
var crouching_state := CrouchingState.new(self)
var rolling_state := RollingState.new(self)
var rolling_air_state := RollingAirState.new(self)
var jumping_state := JumpingState.new(self)

func _ready() -> void:
	current_state = falling_state

	var air_states := State.Group.new(falling_state, jumping_state)

	air_states.add_transition(idle_state, is_on_floor)
	air_states.add_transition(running_state, running_state.should_land_on_wall_or_ceiling)

	var grounded_states := State.Group.new(idle_state, running_state, rolling_state, crouching_state)
	grounded_states.add_transition(jumping_state, is_primary_action_pressed)
	grounded_states.add_transition(rolling_state, rolling_state.should_start_roll)
	
	var standing_states := State.Group.new(idle_state, running_state, crouching_state)
	standing_states.add_transition(falling_state, running_state.should_fall)

	standing_states.add_transition(crouching_state, is_down_pressed)
	crouching_state.add_transition(idle_state, is_down_released)

	idle_state.add_transition(running_state, running_state.is_running)
	running_state.add_transition(idle_state, running_state.is_not_running)

	rolling_state.add_transition(idle_state, rolling_state.should_stop_roll)
	rolling_state.add_transition(rolling_air_state, rolling_state.should_fall)
	rolling_air_state.add_transition(rolling_state, is_on_floor)
	rolling_air_state.add_transition(rolling_state, rolling_state.should_land_on_wall_or_ceiling)

func is_primary_action_pressed() -> bool:
	return Input.is_action_just_pressed("action_primary")

func is_down_pressed() -> bool:
	return Input.is_action_just_pressed("movement_down")

func is_down_released() -> bool:
	return Input.is_action_just_released("movement_down")

func _physics_process(delta: float) -> void:
	transition_to_next_state(delta)
	current_state._physics_process(delta)
	update_rotation_for_ground_angle()
	move_and_slide()
	
	DebugValues.debug("ground_speed", ground_speed / speed_scale)
	DebugValues.debug("ground_angle", ground_angle)
	DebugValues.debug("velocity", velocity / speed_scale)
	DebugValues.debug("speed", velocity.length() / speed_scale)
	DebugValues.debug("global_position", global_position)
	DebugValues.debug("state", current_state.state_name)


func update_rotation_for_ground_angle() -> void:
	up_direction = Vector2.UP.rotated(ground_angle_rad)
	rotation_degrees = - ground_angle

func _process(delta: float) -> void:
	current_state._process(delta)
	
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func transition_to_next_state(delta: float) -> void:
	if lock_transition_frames > 0:
		lock_transition_frames -= 1
		return

	var previous_state = current_state
	var transition := current_state.get_next_transition()

	while transition != null:
		current_state = transition.to_state
		if current_state == previous_state:
			break # Don't loop back
		if transition.reevaluate_after_transition:
			transition = current_state.get_next_transition()
		else:
			break
	
	if current_state != previous_state:
		previous_state._state_exit(delta, current_state)
		current_state._state_enter(delta, previous_state)

func get_input_left_right() -> float:
	if control_lock_timer > 0:
		return 0
	
	var result = 0
	if Input.is_action_pressed("ui_left"): result -= 1
	if Input.is_action_pressed("ui_right"): result += 1
	return result

func count_control_lock(delta: float) -> void:
	if control_lock_timer > 0:
		control_lock_timer -= delta

func start_control_lock() -> void:
	control_lock_timer = control_lock_start

func has_control_lock() -> bool:
	return control_lock_timer > 0

func snap_downward(distance_to_snap:=1000):
	var direction := Vector2.DOWN.rotated(rotation)
	var snap_velocity := direction * distance_to_snap

	var exoected_result := move_and_collide(snap_velocity, true)

	if exoected_result == null or exoected_result.get_remainder().length() == 0:
		# There would not be a collision, so don't bother snapping
		return
	
	move_and_collide(snap_velocity)
