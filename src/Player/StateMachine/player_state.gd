class_name PlayerState
extends State


# Reference to player node
var player: Node3D
# Player properties
var can_move: bool = true
var velocity : Vector3
var angular_acceleration := 5
var is_stepping: bool = false
var is_climbing: bool = false
var climb_direction #set by climb-state
var normal_speed
var input_strength :float 
var move_direction := Vector3.ZERO
var lookdir
var target

func _ready() -> void:
	# States are children of Player so their _ready callback will execute first.
	# Needs to wait for the owner to be ready first
	await owner.ready
	# Casts owner var tp the Player type
	player = owner as Node3D
	# For troubleshooting. Checks if a derived state script is assigned.
	assert(player != null)
	
#func _physics_process(delta):
	##if not player.is_on_floor():
		##state_machine.transition_to("Fall")
	#input_strength = Input.get_action_strength("up") + Input.get_action_strength("down") + Input.get_action_strength("left") + Input.get_action_strength("right")
	#move_direction.x = Input.get_action_strength("left") - Input.get_action_strength("right")
	#move_direction.z = Input.get_action_strength("up") - Input.get_action_strength("down")
	#if player.velocity != Vector3.ZERO:
		#lookdir = player.velocity.normalized()

func _print(msg: String):
	#%Debugger.write(msg)
	print(msg)
