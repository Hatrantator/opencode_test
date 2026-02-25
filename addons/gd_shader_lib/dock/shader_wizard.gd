@tool
extends AcceptDialog

enum MODE {NONE, SPATIAL, CANVASITEM, COMPUTE}

@onready var sub_viewport: SubViewport = $VBoxContainer/SubViewportContainer/SubViewport
@onready var mesh_instance_3d: MeshInstance3D = $VBoxContainer/SubViewportContainer/SubViewport/MeshInstance3D
@onready var option_button: OptionButton = $VBoxContainer/OptionButton

var shader_type := ""
var shader := Shader.new()
var material := ShaderMaterial.new()

func _ready():
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var mesh = mesh_instance_3d.mesh
	mesh_instance_3d.material_override = material
	add_button("lol", true, "rotate")

func update_preview(template_text: String):
	shader.code = shader_type + template_text
	print(shader.code)
	mesh_instance_3d.rotate(Vector3(0,1,0), 45.0)
	material.shader = shader


func _on_custom_action(action: StringName) -> void:
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	match action:
		"rotate": mesh_instance_3d.rotate(Vector3(0,1,0), 45.0)


func _on_line_edit_text_changed(new_text: String) -> void:
	print(new_text)
	update_preview(new_text)


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0: shader_type = """
shader_type spatial;
"""
		1: shader_type = """
shader_type canvas_item;
"""
		2: pass
