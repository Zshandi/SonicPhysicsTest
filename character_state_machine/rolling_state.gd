extends GroundedStateBase
class_name RollingState

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
	apply_acceleration(delta, -1, ch.roll_deceleration_speed, ch.top_speed)
	apply_friction(delta)

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	ch.facing_dir_scale = ch.ground_speed
	ch.sprite.play("rolling")

func _get_slope_factor() -> float:
	if sign(ch.ground_speed) == sign(sin(ch.ground_angle_rad)):
		return ch.slope_factor_rollup
	else:
		return ch.slope_factor_rolldown

func _get_friction() -> float:
	return ch.roll_friction_speed

func should_start_roll() -> bool:
	var result = Input.is_action_just_pressed("movement_down") and \
		(abs(ch.ground_speed) >= ch.min_rolling_start_speed or does_slope_factor_apply())
	return result