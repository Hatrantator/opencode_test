class_name StateMachine
extends Node

# Path to the intital active state. Export it to be able to pick the init state in the inspector
@export var initial_state: NodePath

# The current active state. At the start of the game, we get the 'initial_state'
@onready var state: State = get_node(initial_state)


# Emitted when transitioning to a new state.
signal transitioned(state_name)


func _ready() -> void:
	await owner.ready
	# the state machine assigns iteself to the State obj state_machine property.
	for child in get_children():
		child.state_machine = self
		for grandchild in child.get_children():
			if grandchild is State:
				grandchild.state_machine = self
	state.enter()

# The state machine subscribes to node callbacks and delegates them to the state obj.
func _input(event: InputEvent) -> void:
	state.handle_input(event)
	

func _process(delta: float) -> void:
	state.update(delta)
	

func _physics_process(delta: float) -> void:
	state.physics_update(delta)

# Calls the current state exit() function, then changes the active state
# and calls its enter function.
# Optionally takes a msg dict to pass to the next states enter() func
func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	if not has_node(target_state_name):
		#%Debugger.write("fsm has no "+target_state_name)
		print("fsm has no %s" % target_state_name)
		return
	if state.name == target_state_name:
		return
		
	state.exit()
	state = get_node(target_state_name)
	state.enter(msg)
	emit_signal("transitioned", state.name)
