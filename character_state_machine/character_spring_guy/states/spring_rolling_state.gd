extends State
class_name SpringRollingState

var acceleration := 0.47 * acceleration_scale
var deceleration := 1.5 * acceleration_scale
var friction := 0.15 * acceleration_scale

# Turn rate in radians per second
var head_turn_speed := deg_to_rad(70)
# Max head turn in radians
var head_turn_max := deg_to_rad(70)


var spring_char: CharacterSpringGuy

var wheel_radius: float = 127.5

# Called when the state is about to transition to another state
func _state_exit(_delta: float, _next_state: State) -> void:
	pass


func _init(character: CharacterBody2D, name: String = ""):
	super._init(character, name)
	spring_char = character

# Called when the state is transitioned to from another state
func _state_enter(_delta: float, _previous_state: State) -> void:
	# Calculate the ground speed
	# Linear speed based on velocity that aligns with the ground angle
	var ground_right_dir := Vector2.RIGHT.rotated(spring_char.ground_angle)
	var linear_ground_speed := spring_char.velocity.dot(ground_right_dir)

	# Angular speed of spinning wheel 
	var angular_ground_speed := spring_char.wheel_rotation_speed * wheel_radius

	# Check if they align or not and act accordingly 
	if sign(linear_ground_speed) == sign(angular_ground_speed):
		# If aligned, just take the higher value
		spring_char.ground_speed = max(linear_ground_speed, angular_ground_speed)
		DebugValues.debug("ground_speed transition", "max")
	else:
		# If opposite but one much greater than the other, just use the greater one
		if abs(linear_ground_speed) < abs(angular_ground_speed) / 4:
			spring_char.ground_speed = angular_ground_speed
		elif abs(angular_ground_speed) < abs(linear_ground_speed) / 4:
			spring_char.ground_speed = linear_ground_speed
		else:
			# Otherwise they cancel each other out to some extent
			spring_char.ground_speed = linear_ground_speed + angular_ground_speed

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	var dir := spring_char.get_input_left_right()
	var right_vector := ch.up_direction.rotated(PI / 2)
	DebugValues.debug("right_vector", right_vector)
	if dir != 0:
		spring_char.sprite_facing_dir = sign(dir)
		if sign(dir) != sign(ch.velocity.x):
			spring_char.ground_speed += deceleration * delta * dir
		else:
			spring_char.ground_speed += acceleration * delta * dir
	else:
		spring_char.ground_speed = move_toward(spring_char.ground_speed, 0, friction * delta)
	
	spring_char.velocity = right_vector * spring_char.ground_speed - spring_char.up_direction

	var relative_head_angle := spring_char.up_direction.angle_to(Vector2.UP.rotated(spring_char.head_angle))

	relative_head_angle = move_toward(relative_head_angle, head_turn_max * sign(dir), head_turn_speed * delta)

	spring_char.head_angle = Vector2.UP.angle_to(spring_char.up_direction.rotated(relative_head_angle))

	spring_char.wheel_rotation_speed = spring_char.ground_speed / (wheel_radius)

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	pass
