class_name Bullet3D
extends CharacterBody3D

enum EffectState { NULL, ANTICIPATION, HOLD, IMPACT, SUSTAIN, DECAY }
@onready var current_effect_state: EffectState = EffectState.NULL

@export_group("Time")
@export var allow_process: bool = false
@export var sustain_time: float = 3.5 ## Time the effect sustains after impact
@export var decay_time: float = 4.0 ## Time before the effect decays

@export_group("Movement")
enum MovementMode { IDLE, FORWARD, STEERED, TARGETED, PASSIVE }
enum GravityMode { NONE, NORMAL}
@export var movement_mode: MovementMode = MovementMode.FORWARD
@export var gravity_mode: GravityMode = GravityMode.NORMAL

@export var move_speed := 12.0 ## Character maximum run speed on the ground.
@export var acceleration := 3.0 ## Movement acceleration
@export var angular_acceleration := 5

@export var can_jump: bool = true  # Enable or disable jumping
@export var jump_initial_impulse := 10.0 ## Jump impulse
@export var jump_additional_force := 4.5 ## Jump impulse when player keeps pressing jump
@export var stopping_speed := 7.5

@export_group("Movement_Collision")
enum CollisionMode { PHYSICS_ON, PHYSICS_OFF }
@export var collision_mode: CollisionMode = CollisionMode.PHYSICS_OFF
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var area_shape_3d: CollisionShape3D = $Area3D/CollisionShape3D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"


var move_direction := Vector3.ZERO
var lookdir
var target

func _ready() -> void:
	await animation_player.ready
	anticipation()
	await get_tree().create_timer(decay_time).timeout
	if current_effect_state != EffectState.IMPACT && current_effect_state != EffectState.DECAY:
		decay()

func _physics_process(delta: float) -> void:
	if not allow_process:
		return

	match movement_mode:
		MovementMode.IDLE:
			velocity.x = 0
			velocity.z = 0

		MovementMode.FORWARD:
			# Move forward in the current facing direction
			var forward = -transform.basis.z.normalized()
			velocity.x = forward.x * move_speed
			velocity.z = forward.z * move_speed

		MovementMode.STEERED:
			var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			move_direction = Vector3(input_dir.x, 0, input_dir.y)
			if move_direction.length() > 0:
				move_direction = move_direction.normalized()
				var target_rotation = atan2(-move_direction.x, -move_direction.z)
				rotation.y = target_rotation
				lookdir = Vector3(-sin(target_rotation), 0, -cos(target_rotation)).normalized()
				velocity.x = move_direction.x * move_speed
				velocity.z = move_direction.z * move_speed
			if can_jump and Input.is_action_just_pressed("ui_accept") and is_on_floor():
				velocity.y = jump_initial_impulse


	if gravity_mode == GravityMode.NORMAL:
		if not is_on_floor():
			velocity += get_gravity() * delta

	move_and_slide()

func anticipation() -> void:
	current_effect_state = EffectState.ANTICIPATION
	log_debug("Anticipation state entered", "", true)
	animation_player.play("anticipation")
	animation_player.queue("init")

func hold() -> void:
	current_effect_state = EffectState.HOLD
	log_debug("Hold state entered", "", true)
	animation_player.play("hold")
	allow_process = true

func impact(hit: bool) -> void:
	current_effect_state = EffectState.IMPACT
	log_debug("Impact state entered", "", true)
	allow_process = false
	collision_shape_3d.disabled = true
	area_shape_3d.disabled = true
	if hit:
		animation_player.play("impact")
	else:
		decay()

func sustain() -> void:
	current_effect_state = EffectState.SUSTAIN
	log_debug("Sustain state entered", "", true)

func decay() -> void:
	current_effect_state = EffectState.DECAY
	log_debug("Dissipation state entered", "", true)
	animation_player.play("decay")
	await get_tree().create_timer(3.0).timeout
	get_parent().queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body is Bullet3D and not body.is_in_group("WORLD"):
		log_debug("Body entered: %s" % body.name, "", true)
		current_effect_state = EffectState.IMPACT
		impact(true)


func log_debug(message: String, custom_name: String = "", debug: bool = false) -> void:
	if debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
