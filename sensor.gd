extends RayCast2D
class_name Sensor

func get_collision_depth():
    return get_collision_point().distance_to(global_position)

func get_collision_angle():
    return Vector2.UP.angle_to(get_collision_normal())