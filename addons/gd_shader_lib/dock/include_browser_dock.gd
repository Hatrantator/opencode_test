@tool
extends Control

const ROOT := "res://addons/gd_shader_lib/shaders"
const INCLUDE_ROOT := "res://addons/gd_shader_lib/shaders/includes"
const TEMPLATE_ROOT := "res://addons/gd_shader_lib/shaders/templates"
const TEMPLATE_DATA := {
	"NAME": "Name",
	#"TYPE": "Spatial / CanvasItem / Compute",
	"CATEGORY": "Fragment / Vertex / Other",
	"PREFIX": "gdsl",
	"DESCRIPTION": "Describe your project",
	"FILEPATH": INCLUDE_ROOT
}

@onready var tree := $Tree

@onready var rtl: RichTextLabel = $PanelContainer/RichTextLabel

@onready var popup_menu: PanelContainer = $PopupMenu
@onready var inputs: VBoxContainer = $PopupMenu/ScrollContainer/Inputs
var new_include_fields :Array[LineEdit]= []
var cache_data := {}

@onready var context_menu := PopupMenu.new()
@onready var shader_wizard: AcceptDialog = $ShaderWizard

@onready var accept_dialog: AcceptDialog = $AcceptDialog
@onready var inputs_2: VBoxContainer = $AcceptDialog/Inputs
@onready var option_button: OptionButton = $AcceptDialog/Inputs/OptionButton


func _ready():
	_setup_popup()
	_setup_create_include()
	_setup_context_menu()
	_refresh_tree()

func _refresh_tree():
	tree.clear()
	var root = tree.create_item()
	_scan_directory(ROOT, root)

func _scan_directory(path: String, parent: TreeItem):
	var dir := DirAccess.open(path)
	if dir == null:
		return

	for folder in dir.get_directories():
		var item = tree.create_item(parent)
		item.set_text(0, folder)
		_scan_directory(path + "/" + folder, item)

	for file in dir.get_files():
		if file.ends_with(".gdshaderinc") or file.ends_with(".gdshader") or file.ends_with(".glsl"):
			var item = tree.create_item(parent)
			item.set_text(0, file)
			item.set_metadata(0, path + "/" + file)

func _setup_create_include() -> void:
	for key in TEMPLATE_DATA.keys():
		var ledit := LineEdit.new()
		ledit.placeholder_text = TEMPLATE_DATA[key] 
		inputs_2.add_child(ledit)
		new_include_fields.append(ledit)

func parse_include(path: String) -> Dictionary:
	# header, dependencies, functions
	var parse_dict :Dictionary = {}
	var header: String = ""
	var deps := PackedStringArray()
	var uniforms := PackedStringArray()
	var funcs := PackedStringArray()
	
	var f := FileAccess.open(path, FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line()
		if line.contains("#include"):
			deps.append(line.split("#include")[1].strip_edges())
		if line.right(1) == "{" and not line.contains("for") and not line.contains("if") and not line.contains("else") and not line.begins_with("layout"):
			funcs.append(line+"}")
		if line.begins_with("// @"):
			header += line.trim_prefix("// ") + "\n"
		if line.begins_with("uniform"):
			uniforms.append(line.split("uniform")[1].strip_edges())
		if line.begins_with("global"):
			uniforms.append(line.strip_edges())
		if line.begins_with("layout"):
			uniforms.append(line.split("layout")[1].strip_edges().trim_suffix(";"))
		parse_dict["header"] = header
		parse_dict["deps"] = deps
		parse_dict["uniforms"] = uniforms
		parse_dict["funcs"] = funcs
	return parse_dict

func create_include_from_template(template_path, target_path, data: Dictionary):
	print(template_path)
	print(target_path)
	var template := FileAccess.open(template_path, FileAccess.READ).get_as_text()

	for key in data.keys():
		template = template.replace("{{" + key + "}}", data[key])

	var file := FileAccess.open(target_path, FileAccess.WRITE)
	file.store_string(template)
	file.close()

func _setup_popup() -> void:
	#for key in TEMPLATE_DATA.keys():
		#var ledit := LineEdit.new()
		#ledit.placeholder_text = TEMPLATE_DATA[key] 
		#inputs.add_child(ledit)
		#new_include_fields.append(ledit)
	popup_menu.visible = false

func _setup_context_menu() -> void:
	add_child(context_menu)
	context_menu.add_item("Copy path", 0)
	context_menu.add_item("Copy include", 1)
	context_menu.add_item("Show", 2)
	context_menu.id_pressed.connect(_on_context_menu_pressed)
	#tree.gui_input.connect(_on_tree_gui_input)


func _on_new_btn_pressed() -> void:
	#popup_menu.visible = true
	accept_dialog.popup_centered_clamped()
	

func _on_create_pressed() -> void:
	cache_data.clear()
	var i := 0
	for key in TEMPLATE_DATA.keys():
		cache_data[key] = new_include_fields[i].text
		i += 1
	if cache_data["PREFIX"] == "": cache_data["PREFIX"] = "gdsl"
	if cache_data["FILEPATH"] == "": cache_data["FILEPATH"] = INCLUDE_ROOT
	print(cache_data)
	await create_include_from_template(TEMPLATE_ROOT, INCLUDE_ROOT+"/"+cache_data["NAME"]+".gdshaderinc", cache_data)
	popup_menu.visible = false
	_refresh_tree()


func _on_tree_item_selected() -> void:
	var item :TreeItem = tree.get_selected()
	if item == null:
		return
	
	var meta = item.get_metadata(0)
	if meta != null:
		var parse_data := parse_include(meta)
		rtl.text = "[b]Info / Docs:[/b] \n"+parse_data["header"]
		
		var deps :PackedStringArray = parse_data["deps"]
		if deps.size() > 0:
			rtl.text += "\n[b][color=orange]@dependencies:[/color][/b]\n"
			for d in deps:
				rtl.text += "• " + d + "\n"
		
		var uniforms :PackedStringArray = parse_data["uniforms"]
		if uniforms.size() > 0:
			rtl.text += "\n[b][color=green]@uniforms:[/color][/b]\n"
			for u in uniforms:
				rtl.text += "• " + u + "\n"

		var funcs :PackedStringArray = parse_data["funcs"]
		if funcs.size() > 0:
			rtl.text += "\n[b]@functions:[/b]\n"
			for f in funcs:
				rtl.text += "• " + f + "\n"


func _on_tree_item_activated() -> void:
	var item :TreeItem = tree.get_selected()
	if item == null:
		return
		
	var meta = item.get_metadata(0)
	if meta != null:
		var resource := load(meta)
		EditorInterface.edit_resource(resource)

func _on_context_menu_pressed(id: int):
	var item :TreeItem = tree.get_selected()
	if item == null:
		return

	var path := item.get_metadata(0)
	if typeof(path) == TYPE_STRING:
		match id:
			1: 
				path = '#include "' + path + '"'
				DisplayServer.clipboard_set(path)
			2: shader_wizard.popup_centered_clamped()
			_: 
				print("path copied")
				DisplayServer.clipboard_set(path)

		
func _on_tree_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var item :TreeItem= tree.get_item_at_position(event.position)
		if item == null:
			return

		tree.set_selected(item,0)
		context_menu.popup(Rect2(event.global_position, Vector2.ZERO))


func _on_accept_dialog_confirmed() -> void:
	cache_data.clear()
	var i := 0
	for key in TEMPLATE_DATA.keys():
		cache_data[key] = new_include_fields[i].text
		i += 1
	var template_file := TEMPLATE_ROOT
	var suffix := ".gdshaderinc"
	match option_button.get_selected_id():
		0: 
			cache_data["TYPE"] = "Spatial"
			template_file += "/spatial_include.gdshaderinc.txt"
		1: 
			cache_data["TYPE"] = "CanvasItem"
			template_file += "/canvasitem_include.gdshaderinc.txt"
		2: 
			cache_data["TYPE"] = "Compute"
			template_file += "/compute_shader.glsl.txt"
			suffix = "compute.glsl"
	if cache_data["PREFIX"] == "": cache_data["PREFIX"] = "gdsl"
	if cache_data["FILEPATH"] == "": cache_data["FILEPATH"] = INCLUDE_ROOT
	print(cache_data)
	await create_include_from_template(template_file, INCLUDE_ROOT+"/"+cache_data["NAME"]+suffix, cache_data)
	popup_menu.visible = false
	_refresh_tree()
