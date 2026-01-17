extends SpringChargingState
class_name SpringReleasingState

# Load time in seconds
var spring_release_time: float = 0.1

var jump_power: float = 0

var jump_speed: float = 26 * speed_scale

var sprung := false

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)
	spring_char.head_sprite.position = spring_char.head_min_position
	sprung = false

# Called when the state is transitioned to from another state
func _state_enter(_delta: float, _previous_state: State) -> void:
	var current_pos := spring_char.head_sprite.position
	var total_dist := spring_char.head_min_position.distance_to(spring_char.head_max_position)
	var current_dist := current_pos.distance_to(spring_char.head_min_position)

	current_progression = clampf(current_dist / total_dist, 0, 1)
	jump_power = current_progression

	sprung = false


# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	if sprung: return
	current_progression -= delta / spring_release_time
	if current_progression <= 0:
		current_progression = 0
		spring_char.head_sprite.position = spring_char.head_min_position

		apply_jump()
		sprung = true
	
func apply_jump() -> void:
	var current_angle := spring_char.head_angle
	var direction := Vector2.UP.rotated(current_angle)
	var jump_impulse := direction * jump_speed

	var jump_velocity := jump_impulse * jump_power
	if jump_velocity.dot(spring_char.velocity):
		spring_char.velocity += jump_velocity
	else:
		var perpendicular_velocity = spring_char.velocity.project(jump_velocity.rotated(PI / 2))
		spring_char.velocity = jump_velocity + perpendicular_velocity

# Called for the current state when rendering (i.e. just called from _process)
func _process(delta: float) -> void:
	super._process(delta)
