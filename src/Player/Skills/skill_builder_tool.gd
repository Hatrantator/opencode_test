class_name SkillBuilderTool
extends Node3D

# State Machine
enum EffectState { NULL, ANTICIPATION, HOLD, IMPACT, SUSTAIN, DECAY }
@onready var current_effect_state: EffectState = EffectState.NULL

@export var debug: bool = false
@export_group("Time")
@export var allow_process: bool = false
@export var sustain_time: float = 3.5 ## Time the effect sustains after impact
@export var decay_time: float = 4.0 ## Time before the effect decays

@export_group("Movement")
enum MovementMode { IDLE, ##idle
 FORWARD, ## moves along Vector.FORWARD
 STEERED, ## can be moved manually
 TARGETED, ## follows target
 PASSIVE ## moves with caster
}
enum GravityMode { NONE, NORMAL} ##affected by gravity
@export var movement_mode: MovementMode = MovementMode.FORWARD
@export var gravity_mode: GravityMode = GravityMode.NORMAL

@export var move_speed := 12.0 ## Character maximum run speed on the ground.
@export var acceleration := 3.0 ## Movement acceleration
@export var angular_acceleration := 5

@export var can_jump: bool = true  # Enable or disable jumping
@export var jump_initial_impulse := 10.0 ## Jump impulse
@export var jump_additional_force := 4.5 ## Jump impulse when player keeps pressing jump
@export var stopping_speed := 7.5

func _ready() -> void:
	#await animation_player.ready
	anticipation()
	await get_tree().create_timer(decay_time).timeout
	decay()

func anticipation() -> void:
	current_effect_state = EffectState.ANTICIPATION
	log_debug("Anticipation state entered")

	# Example: scale up and fade in
	tween_properties(self, {
		"scale": [Vector3(2,2,2), 0.4, Tween.TRANS_BACK, Tween.EASE_OUT],
		"modulate:a": [1.0, 0.4]
	})
	#animation_player.play("anticipation")
	#animation_player.queue("init")

func hold() -> void:
	current_effect_state = EffectState.HOLD
	log_debug("Hold state entered")
	#animation_player.play("hold")
	allow_process = true

func impact(hit: bool) -> void:
	current_effect_state = EffectState.IMPACT
	log_debug("Impact state entered")
	allow_process = false
	if hit:
		#animation_player.play("impact")
		sustain()
	else:
		decay()

func sustain() -> void:
	current_effect_state = EffectState.SUSTAIN
	log_debug("Sustain state entered")
	await get_tree().create_timer(sustain_time).timeout
	queue_free()

func decay() -> void:
	current_effect_state = EffectState.DECAY
	log_debug("Dissipation state entered")
	await get_tree().create_timer(sustain_time).timeout
	queue_free()

func tween_properties(target: Object, properties: Dictionary) -> Tween:
	var tween = create_tween()
	for property_path in properties.keys():
		var params = properties[property_path]
		var value = params[0]
		var duration = 0.5
		var trans = Tween.TRANS_SINE
		var ease = Tween.EASE_IN_OUT
		if params.size() > 1:
			duration = params[1]
		if params.size() > 2:
			trans = params[2]
		if params.size() > 3:
			ease = params[3]
		tween.tween_property(target, property_path, value, duration).set_trans(trans).set_ease(ease)
	return tween


func set_collision_shapes(enable: bool) -> void:
	pass


func log_debug(message: String, custom_name: String = "", _debug: bool = false) -> void:
	if debug or _debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
