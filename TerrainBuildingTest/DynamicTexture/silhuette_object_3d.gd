@tool
extends Node3D
class_name SilhouetteObject3D



##Simple usage:
##For each MeshInstance3D, create SilhuetteObject3D.new(), update_mesh_transforms, set material
enum Mode{SILHOUETTE,ALTITUDE}
@export var capture_mode := Mode.SILHOUETTE
@export_tool_button("RESET", "UndoRedo") var btn_rst = self.reset
@export_tool_button("TOP", "Camera3D") var btn_top = self.set_camera_top_view
@export_tool_button("BOT", "Camera3D") var btn_bot = self.set_camera_bot_view
@export_tool_button("SNAP", "LockViewport") var btn_snp = self.take_snapshot
#@export_tool_button("RENDER", "Bake") var btn_rnd = self.render_snapshots
#@export_tool_button("INVERT MASK", "ReverseGradient") var btn_rvs = self.reverse_color
@export var snap_texture_size := Vector2i.ONE * 128
@export var snap_filepath := "res://SilhouetteSnap.png"
@export var mesh_instances :Array[MeshInstance3D] = []
var reversed: bool = false

#@onready var bg: MeshInstance3D = $BG
#@onready var masked_meshes: Node3D = $MaskedMeshes
@onready var mask_material := preload("uid://bu1lrc71wgw5q")
@onready var altitude_material := preload("uid://d3vq1fd58pwd2")
var masked_meshes :Node3D
var sub_viewport: SubViewport
var camera_3d: Camera3D
#@onready var sub_viewport: SubViewport = $SubViewport
#@onready var camera_3d: Camera3D = $SubViewport/Camera3D
#@onready var render_sub_viewport: SubViewport = $RenderSubViewport

var snapshots :Array[Texture2D] = []

func _ready() -> void:
	await _setup_node_structure()

func _setup_node_structure() -> bool:
	sub_viewport = SubViewport.new()
	sub_viewport.size = snap_texture_size
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = true
	sub_viewport.own_world_3d = true
	add_child(sub_viewport)
	sub_viewport.set_owner(get_tree().edited_scene_root)
	
	camera_3d = Camera3D.new()
	camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera_3d.size = snap_texture_size.x / 2
	sub_viewport.add_child(camera_3d)
	camera_3d.set_owner(get_tree().edited_scene_root)
	
	var light = DirectionalLight3D.new()
	light.rotation_degrees.x = -90
	sub_viewport.add_child(light)
	light.set_owner(get_tree().edited_scene_root)

	masked_meshes = Node3D.new()
	masked_meshes.name = "MaskedMeshes"
	sub_viewport.add_child(masked_meshes)
	masked_meshes.set_owner(get_tree().edited_scene_root)
	return true

func draw_object_masks() -> Texture2D:
	for _mesh in mesh_instances:
		if _mesh.mesh.get_surface_count() > -1:
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.transform = _mesh.transform
			mesh_instance.mesh = _mesh.mesh.duplicate()
			masked_meshes.add_child(mesh_instance)
			mesh_instance.set_owner(get_tree().edited_scene_root)
			
			#var mat_mesh := mesh_instance.get_active_material(0)
			var mat_mesh: Material
			if capture_mode == Mode.SILHOUETTE:
				mat_mesh = mask_material.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
				mat_mesh.set_shader_parameter("flat_color", Color.RED)
				mat_mesh.set_shader_parameter("steep_color", Color.BLACK)
			
			if capture_mode == Mode.ALTITUDE:
				mat_mesh = altitude_material.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
			if mat_mesh is not StandardMaterial3D:
				mesh_instance.set_surface_override_material(0, mat_mesh)

	set_camera_top_view()
	var mask = await take_snapshot()
	return mask

# Top view
func set_camera_top_view() -> void:
	print("camera from top")
	camera_3d.global_position = Vector3.ZERO + Vector3.UP * 32.0
	camera_3d.look_at(Vector3.ZERO, Vector3.FORWARD)
	camera_3d.size = 64 ##equals world_partition_size

# Bottom view
func set_camera_bot_view() -> void:
	print("camera from bot")
	camera_3d.global_position = Vector3.ZERO + Vector3.DOWN * 32.0
	camera_3d.look_at(Vector3.ZERO, Vector3.BACK)
	camera_3d.size = 64


func take_snapshot() -> Texture2D:
	await RenderingServer.frame_post_draw
	var texture = sub_viewport.get_texture()
	var img = texture.get_image()
	img.convert(Image.FORMAT_RGBAF)
	var new_tex = ImageTexture.create_from_image(img)
	snapshots.append(new_tex)
	img.save_png(snap_filepath)
	return new_tex


func reset() -> void:
	snapshots.clear()
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
