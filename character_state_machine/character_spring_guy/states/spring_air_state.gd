extends State
class_name SpringAirState

var spring_char: CharacterSpringGuy

# Turn rate in radians per second
var head_turn_speed := deg_to_rad(50)
# Max head turn in radians
var head_turn_max := deg_to_rad(70)

# Called when the state is about to transition to another state
func _state_exit(_delta: float, _next_state: State) -> void:
	pass


func _init(character: CharacterBody2D, name: String = ""):
	super._init(character, name)
	spring_char = character

# Called when the state is transitioned to from another state
func _state_enter(_delta: float, _previous_state: State) -> void:
	spring_char = ch

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	var dir = ch.get_input_left_right()

	if dir != 0:
		spring_char.sprite_facing_dir = sign(dir)

	spring_char.head_angle = move_toward(spring_char.head_angle, head_turn_max * sign(dir), head_turn_speed * delta)
	
	ch.velocity += ch.get_gravity() * delta
	

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	pass
