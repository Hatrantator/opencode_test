class_name Player
extends CustomCharacterBody3D

@export_group("Movement")
## Character maximum run speed on the ground.
@export var allow_process: bool = true
@export var move_speed := 12.0
## Movement acceleration
@export var acceleration := 3.0
@export var angular_acceleration := 5
## Jump impulse
@export var jump_initial_impulse := 20.0
## Jump impulse when player keeps pressing jump
@export var jump_additional_force := 4.5
@export var stopping_speed := 7.5
@export var grid_size: float = 1.0  # Size of the grid for snapping

@export_group("Stats")
@export var strength: int = 5
@export var intelligence: int = 5
@export var dexterity: int = 5
@export var constituion: int = 5
##stat factors
#str:
var throw_factor: float
#int:
#dex:
#con:

var can_move: bool = true
var is_stepping: bool = false
var is_climbing: bool = false
var climb_direction #set by climb-state
var normal_speed
var input_strength :float 
var move_direction := Vector3.ZERO
var lookdir
var target

@onready var camera: Camera3D = $SpringArmPivot/Camera3D

@onready var attack_area_3d: Area3D = $AttackArea3D

@onready var carry_object_pivot: Marker3D = $Visuals/Pivots/CarryObjectPivot
@onready var visuals: Node3D = $Visuals
var pickable_objects: Array = []
var grabbed_object: Node3D

func _ready():
	calc_stat_factors()

func _move(delta: float) -> void:
	if can_move:
		#no_walk.visible = false
		var speed_multi = 1.0
		
		#blend_tree.set(iwr_blend, clampf(input_strength, iwr_blend_pos_idle, iwr_blend_pos_run))
		
		if move_direction:
			speed_multi *= (input_strength)

	#	velocity = velocity.lerp(move_direction.normalized() * (move_speed * speed_multi), acceleration * delta)
		velocity += move_direction.normalized() * (move_speed * speed_multi)

		if not velocity == Vector3.ZERO:
			rotation.y = lerp(rotation.y, atan2(-move_direction.x, -move_direction.y), delta * angular_acceleration)
		if target:
			look_at(target.transform.origin,Vector3.UP)
		else:
			look_at(transform.origin + velocity,Vector3.UP)

		#if velocity != Vector3.ZERO:
			#if target:
				#look_at(target.transform.origin,Vector3.UP)
			#else:
				#look_at(transform.origin + velocity,Vector3.UP)
			
		if move_direction == Vector3.ZERO:
			velocity = velocity.lerp(move_direction.normalized() * move_speed * speed_multi, (acceleration * 2 )* delta)
	#		blend_tree.set(iwr_blend, lerpf(blend_tree.get(iwr_blend), iwr_blend_pos_idle, 0.2))
		#_overstep()
#		_climbing()
		move_and_slide()

#func _overstep():
##	if step_check_top.is_colliding():
##		is_stepping = false
	#if step_check_bot.is_colliding() and not step_check_top.is_colliding():
		#is_stepping = true
		#print("step detected")
		#velocity.y += 8
		#print("overstep")
	#else:
		#is_stepping = false

var frame_cache: int = 0
func _physics_process(delta: float) -> void:
	if allow_process:
		input_strength = Input.get_action_strength("move_up") + Input.get_action_strength("move_down") + Input.get_action_strength("move_left") + Input.get_action_strength("move_right")
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		move_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()  # Convert to 3D (XZ plane)
		move_direction = move_direction.rotated(Vector3.UP, camera.global_rotation.y)

		# Check if there is input
		if move_direction.length() > 0:
			# Normalize the direction for consistent movement
			#move_direction = move_direction.normalized()

			# Rotate the visuals to face the input direction
			var target_rotation = atan2(-move_direction.x, -move_direction.z)
			#visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rotation, angular_acceleration * delta)
			visuals.rotation.y = target_rotation

			 # Set lookdir as the forward direction from target_rotation
			lookdir = Vector3(-sin(target_rotation), 0, -cos(target_rotation)).normalized()

			# Apply movement
			velocity.x = move_direction.x * move_speed
			velocity.z = move_direction.z * move_speed
		else:
			# Decelerate when no input is provided
			#velocity.x = lerp(velocity.x, 0.0, stopping_speed * delta)
			#velocity.z = lerp(velocity.z, 0.0, stopping_speed * delta)
			velocity.x = 0
			velocity.z = 0

		# Add the gravity.
		if not is_on_floor():
			velocity.y += get_gravity().y * delta
		else:
			# Handle jump.
			if Input.is_action_just_pressed("ui_accept") and is_on_floor():
				velocity.y += jump_initial_impulse - (get_gravity().y * delta)

	#	if velocity != Vector3.ZERO:
	#		velocity = snap_to_grid(velocity, grid_size)
		move_and_slide()
		
		frame_cache += 1
		if frame_cache == 15:
			frame_cache = 0
			get_tree().call_group("FoliageManager", "deleteFoliageInstances", global_position)
		
		RenderingServer.global_shader_parameter_set("we_player_position", global_position)
		#%PlayerPosLabel.text = str(global_position.snapped(Vector3.ONE))

func snap_to_grid(_position: Vector3, _grid_size: float) -> Vector3:
	return Vector3(
		round(_position.x / _grid_size) * _grid_size,
		_position.y,  # Keep the Y position unchanged for 3D movement
		round(_position.z / _grid_size) * _grid_size
	)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
#	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
#	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
#	if direction and can_move:
#		velocity.x = direction.x * move_speed
#		velocity.z = direction.z * move_speed
#		lookdir = velocity.normalized()	
#	else:
#		velocity.x = move_toward(velocity.x, 0, move_speed)
#		velocity.z = move_toward(velocity.z, 0, move_speed)
#
#		#if not velocity == Vector3.ZERO:
#			#visuals.rotation.y = lerp(rotation.y, atan2(-move_direction.x, -move_direction.y), delta * angular_acceleration)
#			#if target:
#				#visuals.look_at(target.transform.origin,Vector3.UP)
#			#else:
#				#visuals.look_at(transform.origin + velocity,Vector3.UP)
#
#	if velocity != Vector3.ZERO:
#		if target:
#			visuals.look_at(target.transform.origin,Vector3.UP)
#		else:
#			visuals.look_at(transform.origin + direction,Vector3.UP)
#	move_and_slide()
#	if debug:
#		%Debugger.write(str(global_position))
	
	## for moving objects
	#var push_force = 1.0
	#for i in get_slide_collision_count():
		#var c = get_slide_collision(i)
		#if c.get_collider() is RigidBody3D:
			#c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

func grab_object(object: Node3D) -> bool:
	if not grabbed_object:
		if object is PickableObject && strength >= roundi(object.mass):
			grabbed_object = object
			grabbed_object.grab(true)
			var tween = get_tree().create_tween()
			tween.tween_property(grabbed_object, "global_position", carry_object_pivot.global_position, 0.2)
			await tween.finished
	else:
		if grabbed_object is PickableObject:
			grabbed_object.throw((lookdir + (Vector3.UP * 0.1)) * (strength * throw_factor))
			grabbed_object = null
			
	return true

func _on_pickup_area_3d_body_entered(body: Node3D) -> void:
	if body is PickableObject: pickable_objects.append(body)

func _on_pickup_area_3d_body_exited(body: Node3D) -> void:
	if body is PickableObject:
		if pickable_objects.has(body): pickable_objects.erase(body)

func calc_stat_factors() -> bool:
	throw_factor = 10
	return true

func set_attack_area(set: bool) -> void:
	attack_area_3d.monitoring = set
	attack_area_3d.monitorable = set
