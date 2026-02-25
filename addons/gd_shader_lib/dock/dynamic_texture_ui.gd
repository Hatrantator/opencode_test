@tool
extends Control

@export var textures :Array[Texture2D] = []

const COMPUTE_ROOT := "res://addons/gd_shader_lib/shaders/examples/compute"
const GD_ROOT := "res://addons/gd_shader_lib/shaders/examples/compute"
const DEFAULT_COMPUTE = {
	"HEADER": "#[compute]",
	"VERSION": "\n#version 450",
	"WORKGROUP": "\nlayout(local_size_x = {{X}}, local_size_y = {{Y}}) in;",
	
	"IMAGEUNIFORM": "\nlayout(set = 0, binding = {{BINDID}}, {[FORMAT]}) uniform readonly image2D {{PREFIX}}InTexture;",
	"SHAREDIMAGEUNIFORM": "\nlayout(set = 0, binding = {{BINDID}}, {[FORMAT]}) uniform writeonly restrict image2D {{PREFIX}}OutTexture;",
	"SAMPLER2DUNIFORM": "\nlayout(set = 0, binding = {{BINDID}}) uniform sampler2D {{PREFIX}}SampleTexture;",
	"PARAMSUNIFORM": "\nlayout(set = 0, binding = {{BINDID}}) uniform Params {
	{{PARAMSBODY}}
} {{PREFIX}};",
	"SSBO": "\nlayout(set = 0, binding = {{BINDID}}) buffer {{PREFIX}}Buffer {
	{{PREFIX}}Data data[]
};",
	"MAIN": "\nvoid main() {
	{{MAINBODY}}
}",
}

const COMPUTE_HELP = {
	"FUNCTION": "\nfunc execute_{{PREFIX}}_compute() -> void:",
	"SHADER": "\n	var compute_shader := ComputeHelper.create({{PATH}})",
	"IMAGE": "\n	var {{PREFIX}}_image := Image.new()\n	{{PREFIX}}_image.convert(Image.FORMAT_{{FORMAT}})",
	"INTEXTURE": "\n	var {{PREFIX}}_in_texture := ImageUniform.create({{PREFIX}}_image)",
	"OUTTEXTURE": "\n	var {{PREFIX}}_out_texture := SharedImageUniform.create({{PREFIX}}_in_texture)",
	"UNIFORMARRAY": "\n	compute_shader.add_uniform_array({{ARRAY}})",
	"WORKGROUPS": "\n	var work_groups := Vector3i({{PREFIX}}_image.get_width(),{{PREFIX}}_image.get_height(),1)",
	"RUN": "\n	compute_shader.run(work_groups)\n	ComputeHelper.sync()"
}
const FORMAT :Array = ["rgba8", "rgba16f", "rgba32f"]

@onready var work_group_option_button: OptionButton = $PanelContainer/VBoxContainer/ShaderParam/WorkGroupOptionButton

@onready var tree: Tree = $PanelContainer/VBoxContainer/Tree
@onready var prefix_edit: LineEdit = $PanelContainer/VBoxContainer/Panel/PrefixEdit
@onready var format_option_button: OptionButton = $PanelContainer/VBoxContainer/Panel/FormatOptionButton
@onready var in_out_option_button: OptionButton = $PanelContainer/VBoxContainer/Panel/InOutOptionButton
@onready var name_edit: LineEdit = $PanelContainer/VBoxContainer/ShaderParam/NameEdit


var texture_amount:int = 0
var out_texture :bool = false
var uniforms := PackedStringArray()
var gd_prefix := ""
var gd_script := PackedStringArray()
var gd_uniforms := PackedStringArray()

func _ready() -> void:
	_refresh_tree()

func _refresh_tree():
	tree.clear()
	var root = tree.create_item()
	root.set_text(0,"Added Lines:")
	
	if not uniforms.is_empty():
		var unis = tree.create_item(root)
		unis.set_text(0, "Uniforms")
		for uniform in uniforms:
			var item = tree.create_item(unis)
			item.set_text(0, uniform)
			#item.set_metadata(0, uniform)

func add_new_texture_to_shader(pref: String, inOut: int, format: int) -> void:
	var imageUniform = DEFAULT_COMPUTE["IMAGEUNIFORM"]
	var sharedImageUniform = DEFAULT_COMPUTE["SHAREDIMAGEUNIFORM"]
	var sampler2DUniform = DEFAULT_COMPUTE["SAMPLER2DUNIFORM"]
	var paramUniform = DEFAULT_COMPUTE["PARAMSUNIFORM"]
	var ssboUniform = DEFAULT_COMPUTE["SSBO"]
	var text := ""
	
	var gd_in_tex := COMPUTE_HELP["INTEXTURE"]
	var gd_out_tex := COMPUTE_HELP["OUTTEXTURE"]
	var gd_text := COMPUTE_HELP["IMAGE"]
	match inOut:
		0: 
			text += imageUniform.replace("{{BINDID}}", str(texture_amount)).replace("{{PREFIX}}", pref).replace("{[FORMAT]}",FORMAT[format])
			gd_text += gd_in_tex
			gd_uniforms.append("{{PREFIX}}_in_texture".replace("{{PREFIX}}", pref))
		1: 
			text += sharedImageUniform.replace("{{BINDID}}", str(texture_amount)).replace("{{PREFIX}}", pref).replace("{[FORMAT]}",FORMAT[format])
			gd_text += gd_out_tex
			gd_uniforms.append("{{PREFIX}}_out_texture".replace("{{PREFIX}}", pref))
			out_texture = true
		2: text += sampler2DUniform.replace("{{BINDID}}", str(texture_amount)).replace("{{PREFIX}}", pref)
		3: text += paramUniform.replace("{{BINDID}}", str(texture_amount)).replace("{{PREFIX}}", pref)
		4: text += ssboUniform.replace("{{BINDID}}", str(texture_amount)).replace("{{PREFIX}}", pref)
	texture_amount += 1
	
	gd_text = gd_text.replace("{{PREFIX}}", pref).replace("{{FORMAT}}",FORMAT[format].to_upper())
	
	uniforms.append(text)
	gd_script.append(gd_text)
	update_shader()

func update_shader() -> PackedStringArray:
	var data := PackedStringArray()
	var template := DEFAULT_COMPUTE["HEADER"]+DEFAULT_COMPUTE["VERSION"]
	var workgroup := DEFAULT_COMPUTE["WORKGROUP"]
	var main := DEFAULT_COMPUTE["MAIN"]
	var mainbody := ""
	
	var compute_helper_template := COMPUTE_HELP["FUNCTION"].replace("{{PREFIX}}", gd_prefix)+COMPUTE_HELP["SHADER"]
	
	match work_group_option_button.get_selected_id():
		0: workgroup = workgroup.replace("{{X}}", "8").replace("{{Y}}", "8")
		1: workgroup = workgroup.replace("{{X}}", "16").replace("{{Y}}", "8")
		2: workgroup = workgroup.replace("{{X}}", "16").replace("{{Y}}", "16")
		3: workgroup = workgroup.replace("{{X}}", "32").replace("{{Y}}", "8")
		4: workgroup = workgroup.replace("{{X}}", "32").replace("{{Y}}", "16")
	template += workgroup
	
	if not uniforms.is_empty():
		for uniform in uniforms:
			template += uniform

	if not gd_script.is_empty():
		for text in gd_script:
			compute_helper_template += text
		var uniform_array := "["
		for i in gd_uniforms:
			uniform_array += i+","
		uniform_array += "]"
		compute_helper_template = compute_helper_template.replace("{{PATH}}", "'this is a path'")
		compute_helper_template += COMPUTE_HELP["UNIFORMARRAY"].replace("{{ARRAY}}",uniform_array)
		compute_helper_template += COMPUTE_HELP["WORKGROUPS"].replace("{{PREFIX}}", gd_prefix)
		compute_helper_template += COMPUTE_HELP["RUN"]

	if texture_amount > 0:
		mainbody += "ivec2 uv = ivec2(gl_GlobalInvocationID.xy);"
		mainbody +="\n	vec4 colorIn = imageLoad("+gd_prefix+"InTexture, uv); //reading Image"
		mainbody += "\n	vec3 greyscale = vec3((colorIn.r + colorIn.g + colorIn.b) / 3.0);"
	if out_texture:
		mainbody += "\n	//imageStore("+gd_prefix+"OutTexture, uv, vec4(greyscale.r, greyscale.g, greyscale.b, colorIn.a)); //writing Image"
	main = main.replace("{{MAINBODY}}", mainbody)
	template += main
	
	_refresh_tree()

	data.append(template)
	data.append(compute_helper_template)
	return data

func create_file_from_text(target_path: String, text: String, mode: int):
	match mode:
		0: target_path = target_path+".compute.glsl"
		1: target_path = target_path+".gd"
	print(target_path)
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	print(file.get_open_error())
	file.store_string(text)
	file.close()

func _on_button_pressed() -> void:
	var pref = prefix_edit.text
	gd_prefix = pref
	var inOut :int= in_out_option_button.get_selected_id()
	var format = format_option_button.get_selected_id()
	add_new_texture_to_shader(pref, inOut, format)


func _on_compute_button_pressed() -> void:
	var text = update_shader()[0]
	print(text)
	create_file_from_text(COMPUTE_ROOT+"/"+name_edit.text, text, 0)


func _on_gd_button_pressed() -> void:
	var text = update_shader()[1]
	print(text)
	create_file_from_text(GD_ROOT+"/"+name_edit.text, text, 1)

func _on_tree_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var item :TreeItem= tree.get_item_at_position(event.position)
		if item == null:
			return

		tree.set_selected(item,0)
		DisplayServer.clipboard_set(item.get_text(0))
