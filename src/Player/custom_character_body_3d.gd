class_name CustomCharacterBody3D
extends CharacterBody3D

## TODO:
## + 
@export_group("Debug")
@export var debug: bool = false

# CustomClassVariables
#@onready var animated_sprite_3d: AnimatedSprite3D = $Visuals/AnimatedSprite3D
#@onready var sprite_3d: Sprite3D = $Visuals/Sprite3D

enum mode{IDLE, COMBAT}
var current_mode: int
var can_run := true
var can_attack := true
var is_hidden := false


func _ready():
	#GameManager.set_player(self)
	current_mode = mode.IDLE

func _physics_process(delta):
	for index in get_slide_collision_count():
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()
		if collider is RigidBody3D:
			collider.apply_central_impulse(-collision.get_normal() * 10)
			if debug:
				%Debugger.write("%s bumped into %s" % [self, collider])
