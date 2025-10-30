extends FallingState
class_name JumpingState

var dont_transition_out_of_jumping := 0

func _init(character: Character, name: String = ""):
	super._init(character, ":Jumping" + name)

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)

	dont_transition_out_of_jumping = 0

# Called when the state is transitioned to from another state
func _state_enter(delta: float, previous_state: State) -> void:
	super._state_enter(delta, previous_state)

	ch.velocity.x += -ch.jump_speed * sin(ch.ground_angle_rad)
	ch.velocity.y += -ch.jump_speed * cos(ch.ground_angle_rad)
	# This fixes a weird bug, where at certain angles is_on_floor()
	#  still returns true the next frame after jumping...
	dont_transition_out_of_jumping = 2

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	# Variable jump height
	if not Input.is_action_pressed("action_primary"):
		if ch.velocity.y < -ch.jump_stop_speed:
			ch.velocity.y = - ch.jump_stop_speed
	
	dont_transition_out_of_jumping = max(dont_transition_out_of_jumping - 1, 0)

	super._physics_process(delta)

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	ch.facing_dir_scale = ch.get_input_left_right()
	ch.sprite.play("jumping")

# Override this to disable air movement
func _can_move() -> bool:
	return true