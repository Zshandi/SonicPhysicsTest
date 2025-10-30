extends State
class_name AirStateBase

func _init(character: Character, name: String = ""):
	super._init(character, "Air" + name)

# Called when the state is about to transition to another state
func _transitioning_from(delta: float) -> void:
	super._transitioning_from(delta)

# Called when the state is transitioned to from another state
func _transitioned_to(delta: float) -> void:
	super._transitioned_to(delta)

# Called every frame after the state has been transitioned
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Drag factor: I was a bit confused by this calculation so I left it off
	#  (see https://info.sonicretro.org/SPG:Air_State#Air_Drag)
	# if ch.velocity.y < 0 && ch.velocity.y > -4:
	#     ch.velocity.x -= (ch.velocity.x / 256); # May need to update to use "div"?

	# Apply gravity
	ch.velocity.y += ch.gravity_force * delta
	if ch.velocity.y > ch.top_falling_speed:
		ch.velocity.y = ch.top_falling_speed

# Called for the current state when rendering (i.e. just called from _process)
func _process(delta: float) -> void:
	super._process(delta)