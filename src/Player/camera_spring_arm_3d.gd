extends Node3D

@export var mouse_sensibility: float = 0.005
@export_range(-90.0,0.0,0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(0.0,90.0,0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4

@onready var spring_arm_3d: SpringArm3D = $SpringArm3D



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensibility
		rotation.y = wrapf(rotation.y, 0.0, TAU)
		rotation.x -= event.relative.y * mouse_sensibility
		rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)
		
	if event.is_action_pressed("cam_up"):
		spring_arm_3d.spring_length += 1
	if event.is_action_pressed("cam_down"):
		spring_arm_3d.spring_length -= 1
	
	if event.is_action_pressed("cam_toggle"):
		toggleCam()

func toggleCam() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
