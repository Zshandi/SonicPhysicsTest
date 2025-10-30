extends State
class_name GroundedState

func _init(character: Character, name: String = ""):
	super._init(character, "Air" + name)

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)

# Called when the state is transitioned to from another state
func _state_enter(delta: float, previous_state: State) -> void:
	super._state_enter(delta, previous_state)

	if not previous_state is GroundedState:
		update_ground_angle()
		var dot = ch.velocity.dot(Vector2.RIGHT.rotated(ch.ground_angle_rad))
		ch.ground_speed = ch.velocity.length() * sign(dot)
		

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	update_ground_angle()
	ch.update_rotation_for_ground_angle()
	ch.snap_downward()

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	ch.facing_dir_scale = ch.get_input_left_right()
	ch.sprite.play("standing")

func update_ground_angle():
	var total_normal = Vector2.ZERO
	var total_normal_count = 0
	for sensor in ch.ground_sensors:
		if sensor.is_colliding():
			total_normal += sensor.get_collision_normal()
			total_normal_count += 1
	
	if total_normal_count > 0:
		var avg_normal = total_normal / total_normal_count
		ch.ground_angle = rad_to_deg(avg_normal.angle_to(Vector2.UP))
		if ch.ground_angle < 0:
			ch.ground_angle += 360