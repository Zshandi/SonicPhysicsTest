extends AirStateBase
class_name FallingState

var FALLING_DEBUG := "FALLING"

func _init(character: Character, name: String = ""):
	super._init(character, ":Falling" + name)
	DebugValues.category(FALLING_DEBUG, KEY_F)

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)

# Called when the state is transitioned to from another state
func _state_enter(delta: float, previous_state: State) -> void:
	super._state_enter(delta, previous_state)

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	DebugValues.debug("velocity.x", ch.velocity.x, FALLING_DEBUG)
	DebugValues.debug("top_speed", ch.top_speed, FALLING_DEBUG)
	DebugValues.debug("abs(ch.velocity.x) < ch.top_speed", abs(ch.velocity.x) < ch.top_speed, FALLING_DEBUG)
	DebugValues.debug("velocity.x delta", 0, FALLING_DEBUG)
	DebugValues.debug("  ch.get_input_left_right()", ch.get_input_left_right(), FALLING_DEBUG)
	DebugValues.debug("velocity.x final", ch.velocity.x, FALLING_DEBUG)
	
	# Air movement
	if abs(ch.velocity.x) < ch.top_speed:
		var velocity_x_delta := ch.air_acceleration * ch.get_input_left_right() * delta
		DebugValues.debug("velocity.x delta", velocity_x_delta, FALLING_DEBUG)
		ch.velocity.x += velocity_x_delta
		ch.velocity.x = clamp(ch.velocity.x, -ch.top_speed, ch.top_speed)
	
	DebugValues.debug("velocity.x final", ch.velocity.x, FALLING_DEBUG)

	super._physics_process(delta)

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	ch.facing_dir_scale = ch.get_input_left_right()
	ch.sprite.play("falling")