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
		ground_angle = value
		ground_angle_rad = deg_to_rad(value)

var facing_dir_scale := 1.0:
	set(value):
		if value != 0:
			facing_dir_scale = sign(value)
			%CharacterSprite.scale.x = abs(%CharacterSprite.scale.x) * value

var control_lock_timer := 0.0

var falling_state := FallingState.new(self)
var grounded_state := GroundedState.new(self)
var jumping_state := JumpingState.new(self)

var lock_transition_frames := 0

var current_state: State

@onready
var sprite: AnimatedSprite2D = %CharacterSprite

@onready
var ground_sensors := [%GroundSensor1, %GroundSensor2, %GroundSensor3]

func _ready() -> void:
	current_state = falling_state

	falling_state.add_transition(grounded_state, transition_air_to_grounded)
	jumping_state.add_transition(grounded_state, transition_air_to_grounded)

	grounded_state.add_transition(jumping_state, transition_grounded_to_jumping)
	grounded_state.add_transition(falling_state, transition_grounded_to_falling)
	grounded_state.add_transition(falling_state, grounded_state.should_fall)

func transition_air_to_grounded() -> bool:
	return is_on_floor()

func transition_grounded_to_jumping() -> bool:
	return Input.is_action_just_pressed("action_primary")

func transition_grounded_to_falling() -> bool:
	if is_on_floor(): return false

	for sensor in ground_sensors:
		if sensor.is_colliding() and sensor.get_collision_depth() < 15:
			return false
	
	return true

func _physics_process(delta: float) -> void:
	transition_to_next_state(delta)
	current_state._physics_process(delta)
	update_rotation_for_ground_angle()
	move_and_slide()

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
		current_state._state_enter(delta, current_state)

func get_input_left_right() -> float:
	if control_lock_timer > 0:
		return 0
	
	var result = 0
	if Input.is_action_pressed("ui_left"): result -= 1
	if Input.is_action_pressed("ui_right"): result += 1
	if result != 0:
		print_debug("left/right: ", result)
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

	move_and_collide(snap_velocity)

func ground_angle_within(min_angle: float) -> bool:
	var max_angle := 360 - min_angle
	return ground_angle >= min_angle and ground_angle <= max_angle
