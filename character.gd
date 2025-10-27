extends CharacterBody2D

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

var is_movement_grounded := false:
	set(value):
		is_movement_grounded = value
		if value and is_jumping: is_jumping = false
		if not value and is_crouching: is_crouching = false

const ANGLE_ON_FLOOR := 0
const ANGLE_ON_WALL := 1
const ANGLE_ON_CEILING := 2
var ground_angle_state := ANGLE_ON_FLOOR

var is_rolling := false
var is_jumping := false:
	set(value):
		is_jumping = value
		if value:
			if is_movement_grounded: is_movement_grounded = false

var is_crouching := false

var facing_dir_scale := 1
var movement_dir := 0.0

var control_lock_timer := 0.0

var dont_update_grounded_once := false

@onready
var ground_sensors := [%GroundSensor1, %GroundSensor2, %GroundSensor3]

var DEBUG_SLOPES := "SLOPES"
var DEBUG_JUMP := "JUMP"
func _physics_process(delta: float) -> void:
	_update_ground_stuff(delta)

	var is_left_pressed := Input.is_action_pressed("ui_left")
	var is_right_pressed := Input.is_action_pressed("ui_right")
	var is_crouch_pressed := Input.is_action_pressed("ui_down")
	var is_jump_pressed := Input.is_action_just_pressed("ui_accept")
	var is_jump_held := Input.is_action_pressed("ui_accept")

	if (is_left_pressed and is_right_pressed) or control_lock_timer > 0:
		is_left_pressed = false
		is_right_pressed = false

	movement_dir = 0

	if is_left_pressed:
		facing_dir_scale = -1
		movement_dir = -1
	elif is_right_pressed:
		facing_dir_scale = 1
		movement_dir = 1

	DebugValues.category(DEBUG_JUMP, KEY_J)

	var jump_x := -jump_speed * sin(ground_angle_rad)
	var jump_y := -jump_speed * cos(ground_angle_rad)
	var jump := Vector2(jump_x, jump_y).length()
	DebugValues.debug("jump_x", jump_x / speed_scale, DEBUG_JUMP)
	DebugValues.debug("jump_y", jump_y / speed_scale, DEBUG_JUMP)
	DebugValues.debug("jump", jump / speed_scale, DEBUG_JUMP)

	if is_movement_grounded and is_jump_pressed:
		velocity.x += jump_x
		velocity.y += jump_y
		is_jumping = true
		is_movement_grounded = false
		# This fixes a weird bug, where at certain angles is_on_floor()
		#  still returns true the next frame after jumping...
		dont_update_grounded_once = true

	elif is_movement_grounded:
		is_jumping = false

		if is_crouch_pressed and not is_rolling:
			if ground_speed < min_rolling_start_speed:
				is_crouching = true
			else:
				is_rolling = true
		else:
			is_crouching = false

		DebugValues.category(DEBUG_SLOPES, KEY_A)
		DebugValues.debug("ground_angle", ground_angle, DEBUG_SLOPES)
		DebugValues.debug("ground_speed (start)", ground_speed / speed_scale, DEBUG_SLOPES)

		DebugValues.debug("slope_factor", 0, DEBUG_SLOPES)
		DebugValues.debug("ground_speed Change", 0, DEBUG_SLOPES)
		if ground_angle_state != ANGLE_ON_CEILING:
			var slope_factor = slope_factor_normal
			if is_rolling:
				if sign(ground_speed) == sign(sin(ground_angle_rad)):
					slope_factor = slope_factor_rollup
				else:
					slope_factor = slope_factor_rolldown

			ground_speed -= slope_factor * delta * sin(ground_angle_rad)
		
			DebugValues.debug("slope_factor", slope_factor / acceleration_scale, DEBUG_SLOPES)
			DebugValues.debug("ground_speed Change", (-slope_factor * delta * sin(ground_angle_rad)) / speed_scale, DEBUG_SLOPES)

		if movement_dir != 0 and not is_crouching:
			if sign(movement_dir) != sign(ground_speed):
				if is_rolling:
					ground_speed += roll_deceleration_speed * delta * movement_dir
				else:
					ground_speed += deceleration_speed * delta * movement_dir
			elif abs(ground_speed) < top_speed and not is_rolling:
				ground_speed += acceleration_speed * delta * movement_dir
				ground_speed = clamp(ground_speed, -top_speed, top_speed)
		
		if movement_dir == 0 or is_rolling:
			var effective_friction = roll_friction_speed if is_rolling else friction_speed
			var ground_speed_sign = sign(ground_speed)
			ground_speed -= sign(ground_speed) * effective_friction * delta
			if ground_speed_sign != sign(ground_speed):
				# We stopped, don't jitter
				ground_speed = 0
		
		DebugValues.debug("ground_speed (end)", ground_speed / speed_scale, DEBUG_SLOPES)

		if control_lock_timer <= 0:
			control_lock_timer = 0
			var slope_dir = -1 if ground_angle < 180 else 1
			# Should player slip?
			if abs(ground_speed) < slip_max_speed and ground_angle_within(slip_min_angle) and \
				(sign(movement_dir) != sign(slope_dir) or movement_dir == 0 or ground_angle_state == ANGLE_ON_CEILING): # I added this last one
				# Lock controls (slip)
				control_lock_timer = control_lock_start
				
				# Should player fall?
				if ground_angle_within(fall_min_angle):
					# Detach (fall)
					is_movement_grounded = false;
				else:
					# Depending on what side of the player the slope is, add or subtract 0.5 from Ground Speed to slide down it
					ground_speed += slip_speed_reduction * slope_dir
		else:
			# Tick down timer
			control_lock_timer -= delta;
		
		velocity.x = ground_speed * cos(ground_angle_rad)
		velocity.y = ground_speed * -sin(ground_angle_rad)
	else:
		# Air movement
		if abs(velocity.x) < top_speed:
			velocity.x += air_acceleration * movement_dir * delta
			velocity.x = clamp(velocity.x, -top_speed, top_speed)

		# Variable jump height
		if is_jumping and not is_jump_held:
			if velocity.y < -jump_stop_speed:
				velocity.y = - jump_stop_speed
		
		# Drag factor: I was a bit confused by this calculation so I left it off
		#  (see https://info.sonicretro.org/SPG:Air_State#Air_Drag)
		# if velocity.y < 0 && velocity.y > -4:
		#     velocity.x -= (velocity.x / 256); # May need to update to use "div"?

		# Apply gravity
		velocity.y += gravity_force * delta
		if velocity.y > top_falling_speed:
			velocity.y = top_falling_speed
	
	_update_for_ground_angle()
	move_and_slide()

var DEBUG_SENSORS := "SENSORS"
func _update_ground_stuff(_delta: float):
	var was_movement_grounded = is_movement_grounded

	if dont_update_grounded_once:
		# This fixes a weird bug, where at certain angles is_on_floor()
		#  still returns true the next frame after jumping...
		dont_update_grounded_once = false
	else:
		is_movement_grounded = is_on_floor()

		if was_movement_grounded or is_movement_grounded:
			var total_normal = Vector2.ZERO
			var total_normal_count = 0
			for sensor in ground_sensors:
				if sensor.is_colliding() and sensor.get_collision_depth() < 15 and \
					(not was_movement_grounded or abs(sensor.get_collision_normal().angle_to(up_direction)) < 50):
					is_movement_grounded = true
					total_normal += sensor.get_collision_normal()
					total_normal_count += 1
			DebugValues.category(DEBUG_SENSORS, KEY_S)
			DebugValues.debug("total_normal_count", total_normal_count, DEBUG_SENSORS)
			DebugValues.debug("total_normal", total_normal, DEBUG_SENSORS)
			DebugValues.debug("avg_normal", 0, DEBUG_SENSORS)
			
			if total_normal_count > 0:
				var avg_normal = total_normal / total_normal_count
				ground_angle = rad_to_deg(avg_normal.angle_to(Vector2.UP))
				if ground_angle < 0:
					ground_angle += 360
				
				DebugValues.debug("avg_normal", avg_normal, DEBUG_SENSORS)
	
	if is_rolling and velocity.length() < 0.01 / speed_scale:
		if ground_angle_within(5):
			is_rolling = false

	_update_for_ground_angle()
	if is_movement_grounded:
		if not is_on_floor():
			_snap_downward()

		if not was_movement_grounded:
			# If we just landed, calculate the ground speed from the velocity
			ground_speed = velocity.length()
			var dot = velocity.dot(Vector2.RIGHT.rotated(ground_angle_rad))
			ground_speed *= sign(dot)
	
	ground_angle_state = ANGLE_ON_FLOOR
	if ground_angle_within(ceiling_min_angle):
		ground_angle_state = ANGLE_ON_CEILING
	elif ground_angle_within(wall_min_angle):
		ground_angle_state = ANGLE_ON_WALL

	DebugValues.debug("ground_speed", ground_speed / speed_scale)
	DebugValues.debug("ground_angle", ground_angle)
	DebugValues.debug("ground_angle_state", ground_angle_state)
	DebugValues.debug("is_movement_grounded", is_movement_grounded)
	DebugValues.debug("velocity", velocity / speed_scale)
	DebugValues.debug("speed", velocity.length() / speed_scale)
	DebugValues.debug("global_position", global_position)

func _process(_delta: float) -> void:
	if is_jumping:
		%CharacterSprite.play("jumping")
	elif is_rolling:
		%CharacterSprite.play("rolling")
	elif is_crouching:
		%CharacterSprite.play("crouching")
	elif is_movement_grounded:
		if movement_dir != 0 or abs(ground_speed) > 0.1:
			%CharacterSprite.play("running")
		else:
			%CharacterSprite.play("standing")
	else:
		%CharacterSprite.play("falling")
	%CharacterSprite.scale.x = abs(%CharacterSprite.scale.x) * facing_dir_scale

	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func _update_for_ground_angle():
	if not is_movement_grounded:
		ground_angle = 0
	up_direction = Vector2.UP.rotated(ground_angle_rad)
	rotation_degrees = - ground_angle

func _snap_downward():
	var distance_to_snap := 1000
	var direction := Vector2.DOWN.rotated(rotation)
	var snap_velocity := direction * distance_to_snap

	move_and_collide(snap_velocity)

func ground_angle_within(min_angle: float) -> bool:
	var max_angle := 360 - min_angle
	return ground_angle >= min_angle and ground_angle <= max_angle
