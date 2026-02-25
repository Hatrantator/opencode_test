#virtual base class for all states.
class_name State
extends Node

# Reference to the state machine, to call its 'transisition_to)' method directly.
# Depenedency between state and state machine objects.
# The state machie node will set the state
var state_machine = null


func _ready() -> void:
	await owner.ready
	# to make nested states possible the childs of states also need the state_machine
	for child in get_children():
		child.state_machine = state_machine

# Virtual function. Receives events from the '_unhandled_input()' callback.
func handle_input(event: InputEvent) -> void:
	pass

# Virtual functions. Correspondes to the '_process()' callback.
func update(_delta: float) -> void:
	pass
	
# Virtual function. Corresponds to the '_physics_process()' callback.
func physics_update(_delta: float) -> void:
	pass
	
# Virtual function. Called by the state machine upon changing the active state.
# The 'msg' is a dict with arbitrary data the state can use to init itself
func enter(_msg := {}) -> void:
	pass
	
# Virtual function. Called by the state machine before changing the active state.
# Use to clean up the state
func exit() -> void:
	pass
