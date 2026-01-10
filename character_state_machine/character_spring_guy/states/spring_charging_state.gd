extends State
class_name SpringChargingState

# Release time in seconds
var spring_load_time: float = 0.6

var current_progression: float = 0

var spring_char: CharacterSpringGuy

func _init(character: CharacterBody2D, name: String = ""):
	super._init(character, name)
	spring_char = character

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)

# Called when the state is transitioned to from another state
func _state_enter(delta: float, previous_state: State) -> void:
	super._state_enter(delta, previous_state)
	current_progression = 0


# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	current_progression += delta / spring_load_time
	if current_progression > 1:
		current_progression = 1
	

# Called for the current state when rendering (i.e. just called from _process)
func _process(delta: float) -> void:
	super._process(delta)
	spring_char.head_sprite.position = spring_char.head_min_position \
		.lerp(spring_char.head_max_position, current_progression)
