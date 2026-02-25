@tool
extends Node3D
class_name WorldTileGenerator

##TODO: Streamline this hot mess. Add UI for it. check addon good_old_scape
enum BrushShape{CIRCLE,BOX,TILE}
enum QualityMode{LOW,MEDIUM,HIGH,VERYHIGH,ULTRA} ##map_viewport resolution - 128px,256px,512px,1024px,2048px
enum TerrainDrawMode{HEIGHT,CAVE,WATER,TEXTURE}
enum PolygonDrawMode{OFF,ON}

@export var project_name: String = "NewGoodOldScape"
@export var project_seed: int = 0
@export_tool_button("", "Save") var btn_sve = self.save
@export_tool_button("RESET", "UndoRedo") var btn_rst = self.reset
@export_tool_button("SNAP", "Bake") var btn_snp = self.update_mask
@export_tool_button("CLEAR", "Clear") var btn_clr = self.clear
@export_tool_button("Delete", "Clear") var btn_del = self.clear_map

@export_group("MarchingCube")
@export_range(4, 64, 2, "prefer_slider") var scalar_field_height := 16 ##maximum height of the scalar field
var scalar_field_resolution :int
@export var mesh_max_height := 1.0 ##scales mesh height (height * max_height)
var mc_object :MarchingCube
var marching_cube_mesh :MeshInstance3D
@export var shade_flat := true
@export var terrace:int = 1 ##use with caution
@export var vegetation_slope_threshold := Vector2(0.55,0.9) ##x = begin, y = end. 1.0 = flat TODO:logic should be somewhere else
@export var foliage_offset := 0.33
var flat_surface_transforms :Array[Transform3D] ##instance position for targeted foliagemesh placement -> see FoliageMultiMeshInstance
var slope_surface_transforms :Array[Transform3D] ##instance position for targeted foliagemesh placement -> see FoliageMultiMeshInstance
@export var iso_level := 0.0 ##waterlevel of scalar field. solid/empty
@export_subgroup("HeightMask")
@export var height_texture: Texture2D ##heightmap, samples Red Channel
var height_image: Image
@export_subgroup("Noise")
@export var noise: FastNoiseLite ##optional. adds details to slopes based on noise and its scale (smaller = more details)
@export var noise_strength: float = 1.0 ##factor for noise detail application (higher = more drastic)
@export var noise_slope_threshold := 0.1 ## affected slopes (0.0 = flat)
@export_subgroup("Caves")
@export var cave_height :Vector2 = Vector2(3.0,5.0)
@export var cave_strength := 0.5

@export_group("Painter")
@export var draw_mode: TerrainDrawMode = TerrainDrawMode.HEIGHT
@export var poly_mode: PolygonDrawMode = PolygonDrawMode.OFF
@export var brush_shape: BrushShape = BrushShape.CIRCLE
@export var brush_texture: Texture2D
@export_range(0.0, 1.0, 0.01, "prefer_slider") var brush_height = 0.5
@export_range(2.0, 256.0, 2.0, "prefer_slider") var brush_size := 64.0
@onready var brush_scale_factor := 0.1 #TODO: check this

@export_group("Terrain")
@export var size := Vector2.ONE * 64
@export var material :Material
@export_enum("CENTER","NORTH","EAST", "SOUTH") var orientation = 0
@export_group("Biome and Foliage")
@export var biome := BiomeResource.new()
@export var foliage_resources: Array[FoliageResource] = []




@onready var objects: Node3D = $Objects
@onready var ground: Node3D = $Ground
@onready var vegetation: Node3D = $Vegetation
@onready var _2d: SubViewport = $"2D"  ##Splatmap: Red Base Texture + Vegetation (eg. Grass, no red can be sand for example), green = rocks, blue = road. Needs to be applied to ground and vegetation shader
@onready var slope_root: Node2D = $"2D/Root"
@onready var map_viewport: SubViewport = $MapViewport ##Heightmap: Red = Scalarfieldheight by factor
@onready var brush_root: Node2D = $MapViewport/BrushRoot ##heightmap brush root
@onready var water_map_viewport: SubViewport = $WaterMapViewport
@onready var water_brush_root: Node2D = $WaterMapViewport/Root
@onready var mask: TextureRect = $"2D/Mask"
var partition :PartitionMesh3D
var silhouette :SilhouetteObject3D
var silhuoette_mask :Image
var water_mask :Image

var height_grid: Array ##stores the height in meter per scalar_field_resolution

func save() -> void:
	if not Engine.is_editor_hint(): return
	var base_path := "res://"+project_name
	if not DirAccess.dir_exists_absolute(base_path):
		var _err := DirAccess.make_dir_recursive_absolute(base_path)
		if _err != OK:
			push_error("Failed to create dir: %s (err %d)" % [base_path, _err])
	
	##save_mesh+material
	if marching_cube_mesh.mesh == null: return
	else:
		var _mesh = marching_cube_mesh.mesh.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		var _path := base_path + "/mesh.res"
		#_mesh.resource_path = _path
		ResourceSaver.save(_mesh, _path)
		for i in range(_mesh.get_surface_count()):
			var _mat :Material = _mesh.surface_get_material(i)
			if _mat == null:
				continue
			_path = "%s/material_surface_%d.tres" % [base_path, i]
			#_mat.resource_path = _path
			ResourceSaver.save(_mat.duplicate_deep(), _path)
	if not foliage_resources.is_empty():
		for i in foliage_resources.size():
			var _path = "%s/foliage_%s_%d.tres" % [base_path, foliage_resources[i].foliage_category, i]
			#foliage_resources[i].resource_path = _path
			ResourceSaver.save(foliage_resources[i].duplicate_deep(Resource.DEEP_DUPLICATE_ALL), _path)
	if height_image:
		var _path := base_path + "/height.png"
		var _err := height_image.save_png(_path)
		if _err != OK:
			push_error("Failed to save viewport image")
	if mask.texture:
		var _mask_image := mask.texture.get_image()
		if _mask_image:
			var _path := base_path + "/mask.png"
			var _err := _mask_image.save_png(_path)
			if _err != OK:
				push_error("Failed to save viewport image")
	
	
	
	##1. save resources (ArrayMesh,FoliageResources,Materials,HeightImage,MarchingCubeData,TileData,...)
	printerr("we printing")
	###2. clear()
	#clear()
	#await get_tree().process_frame
	###3. save scene
	#var scene := PackedScene.new()
	#var result := scene.pack(self)
	#if result != OK:
		#push_error("Failed to pack scene")
		#return
	## Get original scene path
	#var path := scene_file_path
	#if path.is_empty():
		#push_error("Scene has no file path")
		#return
	## Save back to disk
	#var err := ResourceSaver.save(scene, path)
	#if err != OK:
		#push_error("Failed to save scene: %s" % err)
	#else:
		#print("Scene saved:", path)
	###4. reset scene
	#reset()

##setters
func set_seed() -> void:
	var _seed = hash(str(project_seed))
	seed(_seed)

func reset() -> void:
	printerr("reset")
	set_seed()
	clear()
	_setup_ground()
	await get_tree().process_frame
	update_mask()
	_print_debug_statistics()

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	reset()
	#_setup_ground()
	#await get_tree().process_frame
	#update_mask()

func _setup_ground() -> void:
	partition = PartitionMesh3D.new()
	partition.mesh = getInstanceMesh()
	ground.add_child(partition)
	partition.set_owner(get_tree().edited_scene_root)
	partition.visible = false
	if biome:
		partition.biome = biome.biome_category
		
	var shape := partition.mesh.create_trimesh_shape()
	var body := StaticBody3D.new()
	body.visible = false
	partition.add_child(body)
	body.set_owner(get_tree().edited_scene_root)
	var collision_shape = CollisionShape3D.new()
	body.add_child(collision_shape)
	collision_shape.set_owner(get_tree().edited_scene_root)
	collision_shape.shape = shape

		##creating the MarchingCubeMesh
	if height_texture:
		height_image = height_texture.get_image()
		scalar_field_resolution = int(size.x) + 3
		mc_object = MarchingCube.new()
		marching_cube_mesh = MeshInstance3D.new()
		marching_cube_mesh.position = Vector3((-scalar_field_resolution*0.5)+0.5, 0.0, (-scalar_field_resolution*0.5)+0.5)
		ground.add_child(marching_cube_mesh)
		marching_cube_mesh.set_owner(get_tree().edited_scene_root)
		generate(marching_cube_mesh)
		var surface_transforms = get_surface_transforms(marching_cube_mesh.mesh)
		#printerr(surface_transforms[0].size())
		flat_surface_transforms = surface_transforms[0]
		slope_surface_transforms = surface_transforms[1]
		var _shape := marching_cube_mesh.mesh.create_trimesh_shape()
		var _body := StaticBody3D.new()
		_body.visible = false
		marching_cube_mesh.add_child(_body)
		_body.set_owner(get_tree().edited_scene_root)
		var _collision_shape = CollisionShape3D.new()
		_body.add_child(_collision_shape)
		_collision_shape.set_owner(get_tree().edited_scene_root)
		_collision_shape.shape = _shape
		
	
	for res in foliage_resources.size():
		var data :Array = foliage_resources[res].getInstancingData()
		for instancing_data in data:
			var _instance_mesh: Mesh = instancing_data[0]
			var _instance_amount: int = instancing_data[1]
			var _scale_range: Vector2 = instancing_data[2]
			var _divide_by_lod: bool = instancing_data[3]
			var _cast_shadow: bool = instancing_data[4]
			var _shape: Shape3D = instancing_data[5]
			var _category = instancing_data[6]
			var _allowed_biomes = instancing_data[7]
			var _mesh_name: String = _instance_mesh.resource_path.get_file().replace(".res", "")
			
			#var planting_cycle: int = 1
			#if height_texture: planting_cycle += 1
			#for i in planting_cycle:
			#var mmi_mat = _instance_mesh.surface_get_material(0).duplicate()
			var mmi = getFoliageMultiMeshInstance(res, 0, _instance_mesh.duplicate(), _scale_range ,_instance_amount, _divide_by_lod,_allowed_biomes, _cast_shadow, _category)
			mmi.name = _mesh_name
			vegetation.add_child(mmi)
			mmi.set_owner(get_tree().edited_scene_root)
			mmi.biome = biome.biome_category
			mmi.level = 0
			#TODO:shove this into foliagemmi
			#if i != 0:
			var new_surfaces: Array[Transform3D]
			if flat_surface_transforms.size() > _instance_amount:
				for j in _instance_amount:
					new_surfaces.append(flat_surface_transforms.pick_random())
			else: new_surfaces = flat_surface_transforms.duplicate()
			mmi.generate_from_transforms(new_surfaces)
			print("transform size:")
			mmi.position = marching_cube_mesh.position
			#else: mmi.generate_instances()
	await get_tree().process_frame
	
	if material:
		if partition and partition.mesh.get_surface_count() > -1: partition.set_surface_override_material(0,material)
		if marching_cube_mesh and marching_cube_mesh.mesh.get_surface_count() > -1: marching_cube_mesh.set_surface_override_material(0,material)

func set_mask() -> void:
	print("setting mask")
	var tex = _2d.get_texture()
	silhuoette_mask = tex.get_image()
	var new_tex = ImageTexture.create_from_image(silhuoette_mask)
	for child in vegetation.get_children():
		if child is FoliageMultiMeshInstance:
			silhuoette_mask.convert(Image.FORMAT_RGBAF)
			var mat = child.multimesh.mesh.surface_get_material(0)
			if mat is not StandardMaterial3D:
				mat.set_shader_parameter("vMaskTexture", new_tex)
	
	var water_mask_tex = water_map_viewport.get_texture()
	water_mask = water_mask_tex.get_image()
	#var 
	var water_mat = $WaterPlane.mesh.surface_get_material(0)
	water_mat.set_shader_parameter("vMaskTexture", water_mask_tex)
	print("mask is set")

func generate(mesh: MeshInstance3D):
	var top_y := 2.5
	height_grid = []
	height_grid.resize(scalar_field_resolution*scalar_field_resolution)
	height_grid.fill(top_y)
	
	mc_object = MarchingCube.new()
	var voxel_grid =  mc_object.VoxelGrid.new(scalar_field_resolution, scalar_field_height)
	for x in range(1, voxel_grid.resolution-1):
		for y in range(1, voxel_grid.height-1):
			for z in range(1, voxel_grid.resolution-1):
				var value: float
				if height_texture:
					value = get_density(x, y, z)
				else:
					value = noise.get_noise_3d(x, y, z)+(y+y%terrace)/float(voxel_grid.resolution)-0.5
				voxel_grid.write(x, y, z, value)
				
				##TODO: fill max_height grid
				if value < 0.0 and y > top_y:
					height_grid[x + scalar_field_resolution * z] = y
	
	#march
	var vertices = PackedVector3Array()
	for x in voxel_grid.resolution-1:
		for y in voxel_grid.height-1:
			for z in voxel_grid.resolution-1:
				march_cube(x, y, z, voxel_grid, vertices)

	#draw
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	if shade_flat:
		surface_tool.set_smooth_group(-1)
	
	for vert in vertices:
		surface_tool.add_vertex(vert)
	
	surface_tool.generate_normals()
	surface_tool.index()
	surface_tool.set_material(material)
	mesh.mesh = surface_tool.commit()

##getters
func getInstanceMesh(lod: int = 0) -> PlaneMesh:
	var _mesh := PlaneMesh.new()
	_mesh.size = Vector2.ONE * size
	var subdivision_length = pow(2,lod)
	var subdivides = max(size.x/subdivision_length - 1, 0)
	_mesh.subdivide_width = subdivides
	_mesh.subdivide_depth = subdivides
	return _mesh

func getFoliageMultiMeshInstance(layer: int, lod: int, instance_mesh: Mesh, scale_range: Vector2 ,instance_amount: int, divide_by_lod: bool,  allowed_biomes: PackedInt32Array, shadow: bool = false, category: String = "GRASS") -> Node3D:
	var mmi := FoliageMultiMeshInstance.new() ##custom class
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.use_colors = true
	mmi.multimesh.mesh = instance_mesh
	mmi.seed = hash(str(project_seed))
	mmi.category = category
	mmi.i_count = instance_amount
	mmi.size = size
	mmi.lod = lod
	mmi.scale_range = scale_range
	mmi.divide = divide_by_lod
	mmi.seed = layer
	mmi.allowed_biomes = allowed_biomes
	mmi.biome = biome.biome_category
	
	if not shadow:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi

func get_viewport_image(vp: SubViewport) -> Image:
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	return vp.get_texture().get_image()

func get_triangulation(x:int, y:int, z:int, voxel_grid:MarchingCube.VoxelGrid):
	var idx = 0b00000000
	idx |= int(voxel_grid.read(x, y, z) < iso_level)<<0
	idx |= int(voxel_grid.read(x, y, z+1) < iso_level)<<1
	idx |= int(voxel_grid.read(x+1, y, z+1) < iso_level)<<2
	idx |= int(voxel_grid.read(x+1, y, z) < iso_level)<<3
	idx |= int(voxel_grid.read(x, y+1, z) < iso_level)<<4
	idx |= int(voxel_grid.read(x, y+1, z+1) < iso_level)<<5
	idx |= int(voxel_grid.read(x+1, y+1, z+1) < iso_level)<<6
	idx |= int(voxel_grid.read(x+1, y+1, z) < iso_level)<<7
	return mc_object.TRIANGULATIONS[idx]

func get_terrain(x: int, z: int) -> Color:
	var u := float(x) / float(scalar_field_resolution - 1)
	var v := float(z) / float(scalar_field_resolution - 1)
	var tx := clampi(int(u * (height_image.get_width() - 1)), 0, height_image.get_width() - 1)
	var tz := clampi(int(v * (height_image.get_height() - 1)), 0, height_image.get_height() - 1)
	return height_image.get_pixel(tx, tz)

func ground_plane_density(y: float) -> float:
	return (0.1 * 0.5) - abs(y)

func terrain_density(x: int, y: int, z: int) -> float:
	var height := get_terrain(x, z).r * mesh_max_height
	return height - float(y)

#func sculpt_density(x: int, y: int, z: int) -> float:
	#return r_field.get_value(x, y, z)


func get_density(x: int, y: int, z: int) -> float:
	var terrain_data := get_terrain(x,z)
	var h := terrain_data.r
	var y_norm :float
	if terrace != 0: y_norm = float(y+y%terrace) / float(scalar_field_height)#-0.5#+(y+y%TERRAIN_TERRACE)/float(RESOLUTION)-0.5
	else: y_norm = float(y) / float(scalar_field_height)
	
	#ground
	var base_density := h * mesh_max_height - y_norm
	var density = -base_density

	#if y > 1.0 and y < (h * mesh_max_height * scalar_field_height) -1.0:
	var cave_center := terrain_data.g * mesh_max_height #(0.0-1.0
	var cave_radius := terrain_data.b * (cave_height.x * 0.5)
	#var cave_window_height = (cave_center * scalar_field_height) - y_norm
	#var cave_window_height = (h * scalar_field_height * 0.65) - y_norm
	var cave_window_height = (terrain_data.g * scalar_field_height * 0.65) - y_norm
	if y < cave_window_height + cave_radius and y > cave_window_height - cave_radius:
		if y > 2.0 and y < h * scalar_field_height:
			var cave_falloff := 1.0 - (y_norm / cave_radius)
			##density += cave_falloff * cave_strength *cave_radius 
			density += pow(cave_falloff, 2.0) * cave_radius * cave_strength
		#var y_snap := y + y % terrace
		#var y_dist := absf(y_snap - (cave_center))
		##var y_dist := absf(y - cave_center)
		#if y_dist < cave_radius:
			#var cave_falloff := 1.0 - (y_dist / cave_radius)
			##density += cave_falloff * cave_strength *cave_radius 
			#density += pow(cave_falloff, 2.0) * cave_radius
	
	## noise on the slopes to break up uniformity
	if noise != null and h > 0.0:
		## calculate slopes:
		var hx := get_terrain(x + 1, z).r
		var hz := get_terrain(x, z + 1).r
		var slope :float = abs(h - hx) + abs(h - hz)
		var slope_strength :float = clamp((slope - noise_slope_threshold), 0.0, 1.0)
		if slope_strength > 0.0:
			var n := noise.get_noise_2d(x, z) * noise_strength
			density -= n * slope_strength
			
	if y < 2:
		density = -1.0
	return density

func get_surface_transforms(mesh: Mesh) -> Array:
	var transforms: Array = []
	var slope_transforms: Array[Transform3D] = []
	var flat_transforms: Array[Transform3D] = []
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	for i in range(0, indices.size(), 3):
		var i0 := indices[i]
		var i1 := indices[i + 1]
		var i2 := indices[i + 2]
		var v0 := vertices[i0]
		var v1 := vertices[i1]
		var v2 := vertices[i2]
		var n0 := normals[i0]
		var n1 := normals[i1]
		var n2 := normals[i2]

		# triangle center
		var center := (v0 + v1 + v2) / 3.0
		if v0.y < center.y: center.y = v0.y
		if v1.y < center.y: center.y = v1.y
		if v2.y < center.y: center.y = v2.y

		var tri_normal := (n0 + n1 + n2).normalized()
		if tri_normal.dot(Vector3.UP) < vegetation_slope_threshold.y: ##TODO: Add slopetransforms
			if tri_normal.dot(Vector3.UP) < vegetation_slope_threshold.x:
				slope_transforms.append(Transform3D(Basis.IDENTITY, center + Vector3.UP * 0.01))
			continue
		
		var center_snap = center.snapped(Vector3i.ONE)
		if center_snap.y < height_grid[center_snap.x + scalar_field_resolution * center_snap.z]:
			continue
		#else: center.y += 1

		for j in 16:
			## offsetting the positions before saving the for another rng layer
			var area := ((v1 - v0).cross(v2 - v0)).length() * 0.5
			var radius := sqrt(area) * foliage_offset
			var angle := randf() * TAU
			var offset := Vector3(
				cos(angle) * radius,
				0.0,
				sin(angle) * radius
			)
			#var r := sqrt(randf()) * radius
			#offset = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
			if offset.length() < radius * 0.3:
				continue
			var pos := center + offset + Vector3.UP * 0.01
			flat_transforms.append(Transform3D(Basis.IDENTITY, pos))
	transforms.append(flat_transforms)
	transforms.append(slope_transforms)
	return transforms

func scalar_field(x:float, y:float, z:float):
	return (x * x + y * y + z * z)/60.0

func march_cube(x:int, y:int, z:int, voxel_grid:MarchingCube.VoxelGrid, vertices:PackedVector3Array):
	var tri = get_triangulation(x, y, z, voxel_grid)
	for edge_index in tri:
		if edge_index < 0: break
		var point_indices = mc_object.EDGES[edge_index]
		var p0 = mc_object.POINTS[point_indices.x]
		var p1 = mc_object.POINTS[point_indices.y]
		var pos_a = Vector3(x+p0.x, y+p0.y, z+p0.z)
		var pos_b = Vector3(x+p1.x, y+p1.y, z+p1.z)
		
		var pos = calculate_interpolation(pos_a, pos_b, voxel_grid)
		vertices.append(pos)

func calculate_interpolation(a:Vector3, b:Vector3, voxel_grid:MarchingCube.VoxelGrid):
	@warning_ignore("narrowing_conversion")
	var val_a = voxel_grid.read(a.x, a.y, a.z)
	@warning_ignore("narrowing_conversion")
	var val_b = voxel_grid.read(b.x, b.y, b.z)
	var t = (iso_level - val_a)/(val_b-val_a)
	return a+t*(b-a)

##updaters
func update_mask() -> void:
	var mesh_instances :Array[MeshInstance3D] = []
	silhouette = SilhouetteObject3D.new()
	add_child(silhouette)
	silhouette.set_owner(get_tree().edited_scene_root)
	
	for child in objects.get_children():
		if child is MeshInstance3D: mesh_instances.append(child)
	if marching_cube_mesh: mesh_instances.append(marching_cube_mesh)
	
	silhouette.mesh_instances = mesh_instances
	mask.texture = await silhouette.draw_object_masks()
	silhouette.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	set_mask()
	#update_materials()

func update_materials() -> void:
	if height_image:
		var mat :Material = partition.get_active_material(0).duplicate()
		if marching_cube_mesh and marching_cube_mesh.mesh.get_surface_count() > -1: marching_cube_mesh.set_surface_override_material(0,mat)

##deletes
func clear() -> void:
	printerr("clear")
	if not flat_surface_transforms.is_empty(): flat_surface_transforms.clear()
	if not slope_surface_transforms.is_empty(): slope_surface_transforms.clear()
	if mask.texture: mask.texture = null
	for child in ground.get_children():
		child.queue_free()
	for child in vegetation.get_children():
		child.queue_free()
	for child in get_children():
		if child is SilhouetteObject3D: child.queue_free()

func clear_map() -> void:
	for child in brush_root.get_children():
		child.queue_free()
	for child in water_brush_root.get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	reset()

## painting
var hover_position: Vector3
var hover_normal: Vector3
var hovering := false
var painting_enabled := true

func set_painting_enabled(enabled: bool):
	painting_enabled = enabled

func set_hover_hit(hit: Dictionary):
	if hit:
		hover_position = hit.position
		hover_normal = hit.normal
		hovering = true
	else:
		hovering = false
	update_gizmos()

func paint_world_positions(pos_array: Array[Vector3]) -> void:
	if draw_mode == TerrainDrawMode.CAVE or draw_mode == TerrainDrawMode.WATER:
		_paint_uv_line(pos_array)
	else:
		for pos in pos_array:
			var uv := _world_to_uv(pos)
			#print(uv)
			if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
				return
			_paint_uv(uv)
	await get_tree().process_frame
	await get_tree().process_frame
	reset()


func paint_world_position(world_pos: Vector3):
	#print(world_pos)
	var uv := _world_to_uv(world_pos)
	print(uv)
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return
	_paint_uv(uv)
	await get_tree().process_frame
	await get_tree().process_frame
	#await get_tree().process_frame
	reset()

func _world_to_uv(world_pos: Vector3) -> Vector2:
	var local := partition.to_local(world_pos)
	var u := (local.x / size.x) + 0.5
	var v := (local.z / size.y) + 0.5
	return Vector2(u, v)

func _paint_uv_line(pos_array: Array[Vector3]) -> void:
	var line = Line2D.new()
	for pos in pos_array:
		var uv := _world_to_uv(pos)
		if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
			return
		var point := uv * Vector2(map_viewport.size)
		line.add_point(point)
	if draw_mode == TerrainDrawMode.CAVE:
		line.modulate = Color(0.0,1.0 * brush_height,1.0 ,1.0)#(Color.GREEN * brush_height)+(Color.BLUE * brush_height)
		line.material = CanvasItemMaterial.new()
		line.material.blend_mode = 1
		line.z_index = 1
		#line.texture = brush_texture
		#line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.name = "cave"
	if draw_mode == TerrainDrawMode.WATER: ##water uses two maps
		##TODO: create new watermap viewport. copy from mapviewport but only the non water heights.
		##eg. depth line should not be water line
		##use blue for has_water
		##sample r channel with a little threshold so water is lower than ground mesh
		##place water on brushheight with slight offset
		var water_line = Line2D.new()
		water_line.points = line.points
		#water_line.modulate = Color(0.0, 1.0 * (clampf(brush_height - 0.05,0.15,1.0)),0.0,1.0)
		water_line.modulate = Color(0.0, 1.0,0.0,1.0)
		water_line.material = CanvasItemMaterial.new()
		water_line.material.blend_mode = 1
		water_line.z_index = 1
		water_line.width = brush_size + 6
		#water_line.texture = brush_texture
		#water_line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		water_line.name = "water_surface"
		water_brush_root.add_child(water_line)
		water_line.set_owner(get_tree().edited_scene_root)
		
		
		line.texture = brush_texture
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.name = "water_underwater"
		line.modulate = Color(1.0 * brush_height,0.0, 0.0 ,1.0* brush_height)
		line.material = CanvasItemMaterial.new()
		line.material.blend_mode = 2
		
	line.width = brush_size
	brush_root.add_child(line)
	line.set_owner(get_tree().edited_scene_root)

func _paint_uv(uv: Vector2):
	var pixel_pos := uv * Vector2(map_viewport.size)
	var brush := Sprite2D.new()
	brush.texture = brush_texture.duplicate(true)
	brush.position = pixel_pos
	brush.centered = true

	brush_scale_factor = brush_size / brush_texture.get_size().x
	brush.scale = Vector2.ONE * brush_scale_factor
	
	match draw_mode:
		TerrainDrawMode.HEIGHT:
			## adding another brush with same settings to watermap
			var _brush := Sprite2D.new()
			_brush.texture = brush_texture.duplicate(true)
			_brush.position = pixel_pos
			_brush.centered = true
			_brush.scale = Vector2.ONE * brush_scale_factor
			_brush.modulate = Color(1.0 * brush_height,0.0,0.0,1.0)
			water_brush_root.add_child(_brush)
			_brush.set_owner(get_tree().edited_scene_root)
			
			brush.modulate = Color(1.0 * brush_height,0.0,0.0,1.0)
			
	brush_root.add_child(brush)
	brush.set_owner(get_tree().edited_scene_root)


func _print_debug_statistics() -> void:
	printerr("Grid min/max value: %s / %s" % [height_grid.min(),height_grid.max()])
	pass

##misc
func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		clear()
