extends GroundedStateBase
class_name RunningState

func _init(character: Character, name: String = ""):
	super._init(character, ":Running" + name)

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)

# Called when the state is transitioned to from another state
func _state_enter(delta: float, previous_state: State) -> void:
	super._state_enter(delta, previous_state)
		

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _physics_process_ground_controls(delta: float):
	apply_acceleration(delta, 1, ch.acceleration_speed, ch.top_speed)
	apply_acceleration(delta, -1, ch.deceleration_speed, ch.top_speed)
	if ch.get_input_left_right() == 0:
		apply_friction(delta)

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	ch.facing_dir_scale = ch.get_input_left_right()
	ch.sprite.play("running")

func _get_slope_factor() -> float:
	return super._get_slope_factor()

func is_running() -> bool:
	return abs(ch.ground_speed) > 0 or ch.get_input_left_right() != 0 or does_slope_factor_apply()

func is_not_running() -> bool:
	return not is_running()