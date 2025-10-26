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

var acceleration_speed = 0.046875 * acceleration_scale
var deceleration_speed = 0.5 * acceleration_scale
var friction_speed = 0.046875 * acceleration_scale

var slope_factor_normal = 0.125 * acceleration_scale
var slope_factor_rollup = 0.078125 * acceleration_scale
var slope_factor_rolldown = 0.3125 * acceleration_scale

var air_acceleration := 0.09375 * acceleration_scale

var gravity_force := 0.21875 * acceleration_scale
var top_falling_speed := 16 * speed_scale

var ground_distance := 5

var wall_min_angle := 46
var wall_max_angle := 360 - wall_min_angle

var ceiling_min_angle := 135
var ceiling_max_angle := 360 - wall_min_angle

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
        if not value and is_rolling: is_rolling = false

const ANGLE_ON_FLOOR := 0
const ANGLE_ON_WALL := 1
const ANGLE_ON_CEILING := 2
var ground_angle_state := ANGLE_ON_FLOOR

var is_rolling := false:
    set(value):
        is_rolling = value
        if value:
            if not is_movement_grounded: is_movement_grounded = true

var is_jumping := false:
    set(value):
        is_jumping = value
        if value:
            if is_movement_grounded: is_movement_grounded = false

var facing_dir_scale := 1

@onready
var ground_sensors := [%GroundSensor1, %GroundSensor2, %GroundSensor3]

var DEBUG_SLOPES := "SLOPES"
func _physics_process(delta: float) -> void:
    _update_ground_stuff(delta)

    var is_left_pressed := Input.is_action_pressed("ui_left")
    var is_right_pressed := Input.is_action_pressed("ui_right")
    var is_jump_pressed := Input.is_action_pressed("ui_accept")

    if is_left_pressed and is_right_pressed:
        is_left_pressed = false
        is_right_pressed = false

    var movement_dir = 0

    if is_left_pressed:
        facing_dir_scale = -1
        movement_dir = -1
    elif is_right_pressed:
        facing_dir_scale = 1
        movement_dir = 1

    if is_movement_grounded and is_jump_pressed:
        velocity.x -= jump_speed * sin(ground_angle_rad);
        velocity.y -= jump_speed * cos(ground_angle_rad);
        is_jumping = true

    elif is_movement_grounded:
        is_jumping = false

        DebugValues.category(DEBUG_SLOPES, KEY_A)
        DebugValues.debug("ground_angle", ground_angle, DEBUG_SLOPES)
        DebugValues.debug("ground_speed (start)", ground_speed, DEBUG_SLOPES)

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
        
            DebugValues.debug("slope_factor", slope_factor, DEBUG_SLOPES)
            DebugValues.debug("ground_speed Change", -slope_factor * delta * sin(ground_angle_rad), DEBUG_SLOPES)

        if movement_dir != 0:
            if sign(movement_dir) != sign(ground_speed):
                ground_speed += deceleration_speed * delta * movement_dir
            elif abs(ground_speed) < top_speed:
                ground_speed += acceleration_speed * delta * movement_dir
                ground_speed = clamp(ground_speed, -top_speed, top_speed)
        
        else:
            var ground_speed_sign = sign(ground_speed)
            ground_speed -= sign(ground_speed) * friction_speed * delta
            if ground_speed_sign != sign(ground_speed):
                # We stopped, don't jitter
                ground_speed = 0
        
        DebugValues.debug("ground_speed (end)", ground_speed, DEBUG_SLOPES)
        
        velocity.x = ground_speed * cos(ground_angle_rad)
        velocity.y = ground_speed * -sin(ground_angle_rad)
    else:
        # Air movement
        if abs(velocity.x) < top_speed:
            velocity.x += air_acceleration * movement_dir * delta
            velocity.x = clamp(velocity.x, -top_speed, top_speed)

        # Variable jump height
        if is_jumping and not is_jump_pressed:
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
    if ground_angle >= ceiling_min_angle and ground_angle <= ceiling_max_angle:
        ground_angle_state = ANGLE_ON_CEILING
    elif ground_angle >= wall_min_angle and ground_angle <= wall_max_angle:
        ground_angle_state = ANGLE_ON_WALL

    DebugValues.debug("ground_speed", ground_speed)
    DebugValues.debug("ground_angle", ground_angle)
    DebugValues.debug("ground_angle_state", ground_angle_state)
    DebugValues.debug("is_movement_grounded", is_movement_grounded)
    DebugValues.debug("velocity", velocity)
    DebugValues.debug("global_position", global_position)

func _process(_delta: float) -> void:
    if is_jumping:
        $SanicStanding.hide()
        $SanicBall.show()
    else:
        $SanicStanding.show()
        $SanicBall.hide()
    
    $SanicStanding.scale.x = abs($SanicStanding.scale.x) * facing_dir_scale

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
