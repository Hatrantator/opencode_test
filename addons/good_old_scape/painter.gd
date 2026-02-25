@tool
extends Node
class_name GOPainter

#PaintPlane (Node3D)
#├─ Plane (MeshInstance3D)
#├─ PaintController (Node)
#└─ PaintViewport (SubViewport)
   #├─ Background (ColorRect)
   #└─ BrushRoot (Node2D)

@export var plane: MeshInstance3D
@export var paint_viewport: SubViewport
@export var plane_size := Vector2i(64, 64)
@export var brush_texture: Texture2D
@export var brush_size := 64.0

@onready var brush_root := paint_viewport.get_node("BrushRoot")

func _ready():
	if Engine.is_editor_hint():
		_setup_material()

func _setup_material():
	pass
	#var mat := StandardMaterial3D.new()
	#mat.albedo_texture = paint_viewport.get_texture()
	#mat.roughness = 1.0
	#plane.material_override = mat

func paint_world_position(world_pos: Vector3):
	print(world_pos)
	var uv := _world_to_uv(world_pos)
	print(uv)
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return
	_paint_uv(uv)

func _world_to_uv(world_pos: Vector3) -> Vector2:
	var local := plane.to_local(world_pos)
	var u := (local.x / plane_size.x) + 0.5
	var v := (local.z / plane_size.y) + 0.5
	return Vector2(u, v)

func _paint_uv(uv: Vector2):
	print("painting")
	var pixel_pos := uv * Vector2(paint_viewport.size)
	var brush := Sprite2D.new()
	brush.texture = brush_texture
	brush.position = pixel_pos
	brush.centered = true

	var scale := brush_size / brush_texture.get_size().x
	brush.scale = Vector2.ONE * scale

	brush_root.add_child(brush)
	brush.set_owner(get_tree().edited_scene_root)
