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
	pass

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	var dir = ch.get_input_left_right()
	if dir != 0:
		spring_char.sprite_facing_dir = sign(dir)
		if sign(dir) != sign(ch.velocity.x):
			ch.velocity.x += deceleration * delta * dir
		else:
			ch.velocity.x += acceleration * delta * dir
	else:
		ch.velocity.x = move_toward(ch.velocity.x, 0, friction * delta)
	
	spring_char.head_angle = move_toward(spring_char.head_angle, head_turn_max * sign(dir), head_turn_speed * delta)

	spring_char.wheel_rotation_speed = ch.velocity.x / (wheel_radius)

	if not ch.is_on_floor():
		ch.velocity += ch.get_gravity()


# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	pass
