extends CharacterBody2D

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

var slope_factor_normal = 0.125
var slope_factor_rollup = 0.078125
var slope_factor_rolldown = 0.3125


var air_acceleration := 0.09375 * acceleration_scale

var gravity_force := 0.21875 * acceleration_scale
var top_falling_speed := 16 * speed_scale

# State variables

var ground_speed := 0.0
var ground_angle := 0.0
var is_on_ground := false
var is_jumping := false

var facing_dir_scale := 1

func _physics_process(delta: float) -> void:
    var is_left_pressed := Input.is_action_pressed("ui_left")
    var is_right_pressed := Input.is_action_pressed("ui_right")
    var is_jump_pressed := Input.is_action_pressed("ui_accept")

    if is_left_pressed and is_right_pressed:
        is_left_pressed = false
        is_right_pressed = false

    if is_left_pressed:
        facing_dir_scale = -1
    elif is_right_pressed:
        facing_dir_scale = 1

    if is_on_ground and is_jump_pressed:
        velocity.x -= jump_speed * sin(deg_to_rad(ground_angle));
        velocity.y -= jump_speed * cos(deg_to_rad(ground_angle));
        is_jumping = true

    elif is_on_ground:
        is_jumping = false

        if is_right_pressed:
            if sign(ground_speed) >= 0:
                ground_speed += acceleration_speed * delta
            else:
                ground_speed += deceleration_speed * delta
        
        elif is_left_pressed:
            if sign(ground_speed) <= 0:
                ground_speed -= acceleration_speed * delta
            else:
                ground_speed -= deceleration_speed * delta
        
        else:
            var ground_speed_sign = sign(ground_speed)
            ground_speed -= sign(ground_speed) * friction_speed * delta
            if ground_speed_sign != sign(ground_speed):
                ground_speed = 0
        
        velocity.x = ground_speed * cos(ground_angle)
        velocity.y = ground_speed * -sin(ground_angle)
    else:
        # Movement
        if is_left_pressed:
            velocity.x -= air_acceleration * delta
            if velocity.x < -top_speed:
                velocity.x = - top_speed
        if is_right_pressed:
            velocity.x += air_acceleration * delta
            if velocity.x > top_speed:
                velocity.x = top_speed

        # Variable jump height
        if is_jumping and not is_jump_pressed:
            if velocity.y < -jump_stop_speed:
                velocity.y = - jump_stop_speed
        # Drag factor
        # if velocity.y < 0 && velocity.y > -4:
        #     velocity.x -= (velocity.x / 256); # May need to update to use "div"?

        # Apply gravity
        velocity.y += gravity_force * delta
        if velocity.y > top_falling_speed:
            velocity.y = top_falling_speed
    
    _update_for_ground_angle()
    move_and_slide()

    var was_on_ground = is_on_ground
    is_on_ground = is_on_floor()

    if is_on_ground:
        # Calculate new ground angle if on ground
        var last_collision := get_slide_collision_count() - 1
        if last_collision >= 0:
            # May need to revamp this
            ground_angle = rad_to_deg(get_slide_collision(last_collision).get_angle())

        if not was_on_ground:
            # If we just landed, calculate the ground speed from the velocity
            ground_speed = velocity.length()
            var dot = velocity.dot(Vector2.RIGHT.rotated(ground_angle))
            ground_speed *= sign(dot)
    
    DebugValues.debug("ground_speed", ground_speed)
    DebugValues.debug("ground_angle", ground_angle)


func _process(_delta: float) -> void:
    if is_jumping:
        $SanicStanding.hide()
        $SanicBall.show()
    else:
        $SanicStanding.show()
        $SanicBall.hide()
    
    $SanicStanding.scale.x = abs($SanicStanding.scale.x) * facing_dir_scale

func _update_for_ground_angle():
    if not is_on_ground:
        ground_angle = 0
    up_direction = Vector2.UP.rotated(deg_to_rad(-ground_angle))
    rotation_degrees = ground_angle