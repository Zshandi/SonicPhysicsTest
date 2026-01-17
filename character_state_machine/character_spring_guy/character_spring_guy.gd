extends CharacterBody2D
class_name CharacterSpringGuy

var framerate := 60
var scaling_factor := 0.8

var speed_scale := framerate * scaling_factor
var acceleration_scale := framerate * framerate * scaling_factor

const down_collision_test_distance := 10

# Node variables

@onready
var head_sprite: Sprite2D = %HeadSprite
@onready
var wheel_sprite: Sprite2D = %WheelSprite
@onready
var head_rotation_node: Node2D = %HeadRotation
@onready
var head_min_position: Vector2 = %HeadMinPosition.position
@onready
var head_max_position: Vector2 = %HeadMaxPosition.position

# State variables

# This is to allow for easily converting to 3D if we decide to:
var velocity_2D: Vector2:
	get:
		return velocity
	set(value):
		velocity = value

var ground_speed := 0.0

var ground_angle := 0.0:
	set(value):
		# Ensure it's always between 0 and 2*PI, without changing the angle
		ground_angle = fmod(value, 2 * PI)
		if ground_angle < 0: ground_angle += 2 * PI

var ground_angle_deg := 0.0:
	set(value):
		ground_angle = deg_to_rad(value)
	get:
		return rad_to_deg(ground_angle)

var facing_dir_scale := 1.0:
	set(value):
		if value != 0:
			facing_dir_scale = sign(value)
			%CharacterSprite.scale.x = abs(%CharacterSprite.scale.x) * facing_dir_scale

var sprite_facing_dir: int = 1

var floor_frames := 0

# Wheel angle in radians
var wheel_angle: float = 0

# Wheel rotation speed in radians / second
var wheel_rotation_speed: float = 0

# Wheel angle in radians
var head_angle: float = 0

var current_state: State
var current_spring_state: State

# Moving states
var state_rolling := SpringRollingState.new(self, "Rolling")
var state_falling := SpringAirState.new(self, "Air")

# Spring states
var state_charging := SpringChargingState.new(self, "Charging")
var state_releasing := SpringReleasingState.new(self, "Releasing")

func _ready() -> void:
	current_state = state_falling
	current_spring_state = state_releasing

	state_falling.add_transition(state_rolling, is_on_floor_recently)
	state_rolling.add_transition(state_falling, is_not_on_floor_recently)

	state_releasing.add_transition(state_charging, is_primary_action_pressed)
	state_charging.add_transition(state_releasing, is_primary_action_released)

func calculate_ground_angle() -> float:
	var normal_total := Vector2.ZERO
	var collision: KinematicCollision2D = null
	if get_slide_collision_count() > 0:
		collision = get_slide_collision(get_slide_collision_count() - 1)
		normal_total += collision.get_normal()
	else:
		# With the snap downward, we don't get a slide collision, so test moving in current down direction
		collision = move_and_collide(-up_direction * down_collision_test_distance, true)
		if collision != null:
			normal_total += collision.get_normal()
	
	if %GroundSensor1.is_colliding():
		normal_total += %GroundSensor1.get_collision_normal()
	if %GroundSensor2.is_colliding():
		normal_total += %GroundSensor2.get_collision_normal()

	if normal_total != Vector2.ZERO:
		return Vector2.UP.angle_to(normal_total)
	
	elif not is_on_floor_recently():
		return 0
	
	else: return ground_angle

func update_ground_angle() -> void:
	ground_angle = calculate_ground_angle()

	%Sensors.rotation = ground_angle

	up_direction = Vector2.UP.rotated(ground_angle)
	
	DebugValues.debug("ground_angle", ground_angle)
	DebugValues.debug("up_direction", up_direction)

func is_not_on_floor_recently(): return not is_on_floor_recently()

func is_on_floor_recently(): return floor_frames > 0

func is_primary_action_pressed() -> bool:
	return Input.is_action_just_pressed("action_primary")

func is_primary_action_released() -> bool:
	return Input.is_action_just_released("action_primary")

func get_input_left_right() -> float:
	var result = 0
	if Input.is_action_pressed("ui_left"): result -= 1
	if Input.is_action_pressed("ui_right"): result += 1
	return result

func _physics_process(delta: float) -> void:
	update_ground_angle()

	current_state = transition_to_next_state(current_state, delta)
	current_state._physics_process(delta)

	current_spring_state = transition_to_next_state(current_spring_state, delta)
	current_spring_state._physics_process(delta)
	#update_rotation_for_ground_angle()

	if is_on_floor():
		floor_frames = 3
	else:
		floor_frames -= 1
	
	move_and_slide()
	wheel_angle += wheel_rotation_speed * delta

func _process(delta: float) -> void:
	current_state._process(delta)
	current_spring_state._process(delta)

	wheel_sprite.rotation = wheel_angle
	head_rotation_node.rotation = head_angle

	head_sprite.scale.x = sprite_facing_dir
	wheel_sprite.scale.x = sprite_facing_dir
	
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func transition_to_next_state(_current_state: State, delta: float) -> State:
	var previous_state = _current_state
	var transition := _current_state.get_next_transition()

	while transition != null:
		_current_state = transition.to_state
		if _current_state == previous_state:
			break # Don't loop back
		if transition.reevaluate_after_transition:
			transition = _current_state.get_next_transition()
		else:
			break
	
	if _current_state != previous_state:
		previous_state._state_exit(delta, _current_state)
		_current_state._state_enter(delta, previous_state)
	
	return _current_state
