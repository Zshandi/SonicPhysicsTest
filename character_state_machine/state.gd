extends RefCounted
class_name State

var ch: Character
var state_name: String

var transitions: Array[StateTransition]

func add_transition(to_state: State, condition: Callable):
	var transition = StateTransition.new()
	transition.from_state = self
	transition.to_state = to_state
	transition.condition = condition
	transitions.push_back(transition)

func get_next_transition() -> StateTransition:
	for transition in transitions:
		if transition.condition.call():
			return transition
	return null

func _init(character: Character, name: String = ""):
	ch = character
	state_name = name

# Called when the state is about to transition to another state
func _transitioning_from(_delta: float) -> void:
	pass

# Called when the state is transitioned to from another state
func _transitioned_to(_delta: float) -> void:
	pass

# Called every frame after the state has been transitioned
func _physics_process(_delta: float) -> void:
	pass

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	pass