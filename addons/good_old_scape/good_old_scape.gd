@tool
extends EditorPlugin

var paint_controller: Node = null
var brush_gizmo := BrushGizmo.new()
var painting_enabled := true #TODO: add interface with button
var ignore_3d_motion := false
var ignore_painting := false
var pos_array :Array[Vector3] = []
var mbl_cache := false
var frame_cache := 0

func _enter_tree():
	add_node_3d_gizmo_plugin(brush_gizmo)
	print("Plane Painter Plugin enabled")

func _exit_tree():
	remove_node_3d_gizmo_plugin(brush_gizmo)
	print("Plane Painter Plugin disabled")

func _handles(object: Object) -> bool:
	return object is WorldTileGenerator

func _edit(object: Object):
	if object is WorldTileGenerator: paint_controller = object

func _process(delta: float) -> void:
	if mbl_cache:
		frame_cache += 1
		if frame_cache == 6:
			frame_cache = 0
			print("still pressed")

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	
	##TODO: Click (Selects) and Click+Drag(Brushheight)
	## selects.size() > 1 = we draw lines
	## right_click = delete last select
	
	
	
	if not painting_enabled or paint_controller == null:
		return 0
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		ignore_3d_motion = event.is_pressed()
		print(ignore_3d_motion)
		return 0
	if event is InputEventMouseMotion and not ignore_3d_motion:
		#if not mbl_cache:
		var hover = _update_hover(camera, event.position)
		update_overlays()
		return hover
		#else: print("mouse crewsing: "+str(event.relative.y))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed and not mbl_cache:
		if event.is_pressed() and not mbl_cache:
			print("just pressed")
			mbl_cache = true
		if event.is_released(): ##stuff from is_pressed() goes here
			mbl_cache = false
			print("release")
			print(pos_array.size())
			var hit = _raycast(camera, event.position)
			pos_array.append(hit.position)
			paint_controller.paint_world_positions(pos_array)
			pos_array.clear()
			return 1
	return 0

func _update_hover(camera: Camera3D, mouse_pos: Vector2) -> int:
	var hit = _raycast(camera, mouse_pos)
	paint_controller.set_hover_hit(hit)
	if hit:
		if mbl_cache and frame_cache >= 1:
			if not pos_array.has(Vector3(hit.position.x, 0, hit.position.z).snapped(Vector3.ONE)):
				#if hit.position.distance_to() >= 8.0:
				print("new point in line")
				pos_array.append(Vector3(hit.position.x, 0, hit.position.z).snapped(Vector3.ONE))
		paint_controller.update_gizmos()
		return 1
	else: return 0


func _raycast(camera: Camera3D, mouse_pos: Vector2) -> Dictionary:
	var from = camera.project_ray_origin(mouse_pos)
	var dir = camera.project_ray_normal(mouse_pos)
	var to = from + dir * 10000.0

	var space = camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	return space.intersect_ray(query)
