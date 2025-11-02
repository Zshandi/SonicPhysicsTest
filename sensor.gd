extends RayCast2D
class_name Sensor

func get_collision_depth():
    return get_collision_point().distance_to(global_position)

func get_collision_angle():
    return get_collision_normal().angle_to(Vector2.UP)