extends AirStateBase
class_name FallingState

func _init(character: Character, name: String = ""):
	super._init(character, ":Falling" + name)

# Called when the state is about to transition to another state
func _transitioning_from(delta: float) -> void:
	super._transitioning_from(delta)

# Called when the state is transitioned to from another state
func _transitioned_to(delta: float) -> void:
	super._transitioned_to(delta)

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	# Air movement
	if abs(ch.velocity.x) < ch.top_speed:
		ch.velocity.x += ch.air_acceleration * ch.get_input_left_right() * delta
		ch.velocity.x = clamp(ch.velocity.x, -ch.top_speed, ch.top_speed)
	
	super._physics_process(delta)

# Called for the current state when rendering (i.e. just called from _process)
func _process(delta: float) -> void:
	ch.facing_dir_scale = ch.get_input_left_right()
	ch.sprite.play("falling")

	super._process(delta)

# Override this to disable air movement
func _can_move() -> bool:
	return true