extends RefCounted
class_name StateTransition

var from_state: State
var to_state: State

var condition: Callable
var reevaluate_after_transition: bool