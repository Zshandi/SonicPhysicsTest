extends CharacterBody2D

var framerate := 60
var scaling_factor := 1.5
var speed_scale := framerate * scaling_factor
var acceleration_scale := framerate * framerate * scaling_factor

# Setting variables

var top_speed := 6 * speed_scale

var jump_speed := 6.5 * speed_scale
var jump_stop_speed := 4 * speed_scale

var air_acceleration := 0.09375 * acceleration_scale

var gravity_force := 0.21875 * acceleration_scale
var top_falling_speed := 16 * speed_scale

# State variables

var ground_speed := 0.0
var is_on_ground := false
var is_jumping := false

func _physics_process(delta: float) -> void:
    var is_left_pressed := Input.is_action_pressed("ui_left")
    var is_right_pressed := Input.is_action_pressed("ui_right")
    var is_jump_pressed := Input.is_action_pressed("ui_accept")

    is_on_ground = is_on_floor()

    if is_on_ground:
        var ground_angle = 0 # TODO Calculate ground angle in degrees

        if is_jump_pressed:
            velocity.x -= jump_speed * sin(deg_to_rad(ground_angle));
            velocity.y -= jump_speed * cos(deg_to_rad(ground_angle));
            is_jumping = true
        else:
            is_jumping = false
        # TODO: Ground movement
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
    
    move_and_slide()