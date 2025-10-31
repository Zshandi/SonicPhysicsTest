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
func _state_exit(_delta: float, _next_state: State) -> void:
	pass

# Called when the state is transitioned to from another state
func _state_enter(_delta: float, _previous_state: State) -> void:
	pass

# Called every frame after the state has been transitioned
func _physics_process(_delta: float) -> void:
	pass

# Called for the current state when rendering (i.e. just called from _process)
func _process(_delta: float) -> void:
	pass

class Group:
	extends RefCounted

	var states: Array[State]

	func _init(st1_or_list: Variant, st2: State = null, st3: State = null, st4: State = null) -> void:
		if st1_or_list is State:
			states.push_back(st1_or_list)
		else:
			for st in st1_or_list:
				states.push_back(st)
		
		if st2 != null:
			states.push_back(st2)
		if st3 != null:
			states.push_back(st3)
		if st4 != null:
			states.push_back(st4)
	
	## condition should be a Callable or function name
	func add_transition(to_state: State, condition: Variant) -> void:
		assert(condition is Callable or condition is String)
		if condition is Callable:
			for st in states:
				st.add_transition(to_state, condition)
		elif condition is String:
			for st in states:
				st.add_transition(to_state, Callable(st, condition))
	
	func set_all(property: StringName, value: Variant) -> void:
		for st in states:
			if property in st:
				st.set(property, value)