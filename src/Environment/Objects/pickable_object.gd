class_name PickableObject
extends RigidBody3D

enum DestructionMode { NONE, DESTROYABLE }
@export var destruction_mode: DestructionMode = DestructionMode.DESTROYABLE
@export var size_multiplicator: float = 1.0

var anchor_point: Marker3D
var grabbed: bool = false
var thrown: bool = false


@onready var mesh: MeshInstance3D = $Mesh
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var destruction_particles_3d: GPUParticles3D = $Marker3D/DestructionParticles3D
@onready var area_3d: Area3D = $Marker3D/Area3D
@onready var area_collision_shape_3d: CollisionShape3D = $Marker3D/Area3D/AreaCollisionShape3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var visible_on_screen: bool = false

#var thrust = Vector2(0, -250)
#var torque = 20000
#
#func _integrate_forces(state):
	#if Input.is_action_pressed("ui_up"):
		#state.apply_force(thrust.rotated(rotation))
	#else:
		#state.apply_force(Vector2())
	#var rotation_direction = 0
	#if Input.is_action_pressed("ui_right"):
		#rotation_direction += 1
	#if Input.is_action_pressed("ui_left"):
		#rotation_direction -= 1
	#state.apply_torque(rotation_direction * torque)

func _ready() -> void:
	change_size()

func grab(is_grabbed: bool) -> void:
	grabbed = is_grabbed
	freeze = is_grabbed
	thrown = false

func throw(velocity: Vector3) -> void:
	thrown = true
	grabbed = false
	freeze = false
	apply_central_impulse(velocity)
	apply_torque(Vector3.FORWARD * 0.15)

func change_size() -> void:
	mass *= size_multiplicator
	mesh.scale *= size_multiplicator
	destruction_particles_3d.amount = roundi(destruction_particles_3d.amount * size_multiplicator)
	collision_shape_3d.scale *= size_multiplicator
	area_collision_shape_3d.shape.radius *= size_multiplicator

#func _physics_process(delta: float) -> void:
	#if thrown:
		#for body in get_colliding_bodies():
			#if 
			#var collider_shape = get_contact_collider_shape(i)
			#var collider_shape_index = get_contact_collider_shape_index(i)

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	await get_tree().create_timer(5.0).timeout ##this 
	freeze = true

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	visible_on_screen = true
	freeze = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if thrown and body is CharacterBody3D:
		print(body) ##cast the damage
	elif thrown:
		get_tree().call_group("FoliageManager", "deleteFoliageInstances", Vector3(global_position.x, 0, global_position.z))
		print(body)
	if thrown:
		if destruction_mode == DestructionMode.DESTROYABLE:
			freeze = true
			animation_player.play("destroy")


func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if thrown and body is CharacterBody3D:
		print(body) ##cast the damage
	elif thrown:
		var coll_shape = body.shape_owner_get_owner(body.shape_find_owner(body_shape_index))
		get_tree().call_group("FoliageManager", "deleteFoliageInstances", coll_shape.global_position, size_multiplicator, coll_shape)
		get_tree().call_group("FoliageManager", "deleteFoliageInstances", Vector3(global_position.x, 0, global_position.z), size_multiplicator)
	if thrown:
		if destruction_mode == DestructionMode.DESTROYABLE:
			freeze = true
			animation_player.play("destroy")
