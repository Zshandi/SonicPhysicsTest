extends GroundedStateBase
class_name SpindashState

var spinrev := 0.0
var SPINDASH_DEBUG := "SPINDASH"

func _init(character: Character, name: String = ""):
	super._init(character, ":Sindash" + name)
	DebugValues.category(SPINDASH_DEBUG, KEY_N)

# Called when the state is about to transition to another state
func _state_exit(delta: float, next_state: State) -> void:
	super._state_exit(delta, next_state)
	var speed := (8.0 + floorf(spinrev + 0.5) / 2) * ch.speed_scale
	ch.ground_speed = ch.facing_dir_scale * speed
	DebugValues.debug("spinrev", spinrev, SPINDASH_DEBUG)
	DebugValues.debug("ground_speed", ch.ground_speed / ch.speed_scale, SPINDASH_DEBUG)

# Called when the state is transitioned to from another state
func _state_enter(delta: float, previous_state: State) -> void:
	super._state_enter(delta, previous_state)
	spinrev = 2.0
	ch.ground_speed = 0.0

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if Input.is_action_just_pressed("action_primary"):
		spinrev += 2
	else:
		spinrev -= ceil(spinrev * 4) / 256
	spinrev = clamp(spinrev, 0, 8)
	DebugValues.debug("spinrev", spinrev, SPINDASH_DEBUG)
	DebugValues.debug("ground_speed", ch.ground_speed, SPINDASH_DEBUG)

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	ch.sprite.play("spindash")