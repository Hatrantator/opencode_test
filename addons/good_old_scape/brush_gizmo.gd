@tool
extends EditorNode3DGizmoPlugin
class_name BrushGizmo

var brush_material: StandardMaterial3D
var indicator_material: StandardMaterial3D
var line_material: StandardMaterial3D

func _init():
	line_material = StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	brush_material = StandardMaterial3D.new()
	brush_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	brush_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brush_material.albedo_color = Color(0.2, 1.0, 0.2, 0.35)
	brush_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	indicator_material = StandardMaterial3D.new()
	indicator_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.albedo_color = Color(1.0, 0.4, 0.1, 0.35)
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	

func _has_gizmo(node: Node3D) -> bool:
	return node != null and node is WorldTileGenerator

func _redraw(gizmo: EditorNode3DGizmo):
	#print("redraw gizmo")
	gizmo.clear()
	
	var node := gizmo.get_node_3d()
	var controller :Node3D = gizmo.get_node_3d()
	if controller == null:
		return

	if not controller.hovering:# or not controller.painting_enabled:
		return

	var up :Vector3 = Vector3.UP#controller.hover_normal.normalized()
	var tangent := up.cross(Vector3.RIGHT)
	if tangent.length_squared() < 0.001:
		tangent = up.cross(Vector3.FORWARD)
	tangent = tangent.normalized()
	var bitangent := tangent.cross(up)
	var basis := Basis(tangent, up, bitangent)
	
	var h = controller.scalar_field_height * controller.brush_height# * brush_img.get_pixel(x,z).r
	var gizmo_pos = controller.hover_position.snapped(Vector3.ONE)
	gizmo_pos.y = h * 0.5
	var brush_size :float = controller.brush_size * 0.125
	var xform := Transform3D(basis, controller.hover_position.snapped(Vector3.ONE))
	#var xform := Transform3D(basis, gizmo_pos)
	
	
	if controller.brush_shape == controller.BrushShape.CIRCLE:
		var disk := CylinderMesh.new()
		disk.top_radius = brush_size * 0.5
		disk.bottom_radius = brush_size * 0.5
		disk.height = .25
		disk.radial_segments = 48
		gizmo.add_mesh(disk, brush_material, xform)
	else:
		var quad := BoxMesh.new()
		quad.size = Vector3(controller.brush_size, 0.1, controller.brush_size)
		gizmo.add_mesh(quad, brush_material, xform)
		
	if controller.draw_mode == controller.TerrainDrawMode.WATER:
		brush_material.albedo_color = Color(0.2, 0.478, 1.0, 0.349)
	else: brush_material.albedo_color = Color(0.2, 1.0, 0.2, 0.35)
	
	# --- grid indicator cubes ---
	var grid_step := 1.0
	var half = brush_size * 0.5
	var space := node.get_world_3d().direct_space_state

	# number of cells per side TODO: make work
	var cells := int(brush_size/ grid_step)

	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * grid_step * 0.5#Vector3(0.5, 0.5, 0.5)

	var brush_img :Image = controller.brush_texture.get_image().duplicate()
	#brush_img.resize(cells,cells)
	
	for x in range(cells):
		for z in range(cells):
			# local brush-space position (centered)
			var lx = -half + grid_step * 0.5 + x * grid_step
			var lz = -half + grid_step * 0.5 + z * grid_step
			var local_pos := Vector3(lx, 0.0, lz)
			
			if controller.brush_shape == controller.BrushShape.CIRCLE:
				if Vector2(lx, lz).length() > half:
					continue
			var sample_origin := xform.origin + Basis.IDENTITY * local_pos
			var from := sample_origin + up * 5.0
			var to := sample_origin - up * 5.0
			var query := PhysicsRayQueryParameters3D.create(from, to)
			query.collide_with_bodies = true
			query.collide_with_areas = false
			var hit = space.intersect_ray(query)
			if not hit:
				continue
				
				
			
				
			var cube_pos = Vector3(sample_origin.x,hit.position.y , sample_origin.z) + up * 1.0
			#var cube_pos = Vector3(sample_origin.x,hit.position.y, sample_origin.z) + up * 1.0
			cube_pos = cube_pos.snapped(Vector3.ONE)
			var cube_xform := Transform3D(Basis(), cube_pos)
			gizmo.add_mesh(cube, indicator_material, cube_xform)
	#var center = controller.hover_position
	#var radius = brush_size * 0.05
	##var radius = 1.0
#
	#var points := PackedVector3Array()
	#const STEPS := 48
#
	#for i in STEPS:
		#var a := TAU * float(i) / STEPS
		#var x = cos(a) * radius
		#var z = sin(a) * radius
		#points.append(center + Vector3(x, 0.01, z))
	#gizmo.add_lines(points, line_material, false, Color(0.2, 1.0, 0.2))
