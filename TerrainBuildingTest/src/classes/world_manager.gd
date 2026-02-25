@tool
class_name WorldManager
extends Node3D

###manager data
var setup_finished: bool = false
@export_tool_button("CLEAR ALL") var btn_clear = self._deleteNodeStructure
@export_tool_button("RESET") var btn_reset = self.resetSetup
@export var debug: bool = false ##only loads nodes, without instancing
@export var player: Node3D
@export var foliage_resources: Array[FoliageResource] = []
@export var lod_amount: int = 3
@export var lod_visibility_step: float = 50.0
@export var render_distance:int = 2 # Render distance for the world generation in chunks
@export_category("Biome Texture")
@export var texture_size := Vector2i(512, 512)
@export var texture_origin := Vector2i(0, 0) ##Starting point @biomemap
@export var pixels_per_grid := 1.0
@export var biomes_data :PackedFloat32Array
###working data
var layer_data: Dictionary = {}
var ground_mesh_data: Array = []
var chunk_data: Array = [] #[TilePosition[LOD0,LOD1,LOD2,...],...]
var collision_data: Array = []

##conditions
#....
###creation_data
##exports
#@export_tool_button("Generate Multimesh") var gen_multimesh = self.generate_instances ##generates multimesh based on count and size/mesh.size
#@export var count: int = 1024 ##amount of instances
@export_category("Mesh Setup")
@export var mesh = PlaneMesh.new()
@export var size: Vector2 = Vector2(64.0,64.0) ##area where instances are spawned centered at (0.0,0.0)
#@export var target_mesh: MeshInstance3D
##local
var grid :GridHelper
var biome_9x9 :Dictionary
###removing data - debug exports only
##exports
#@export_tool_button("Cut Multimesh") var cut_multimesh = self.cut_grass_around
@export var cut_position: Vector3 = Vector3.ZERO
@export var cut_radius: float = 2.0
##local

func _ready() -> void:
	if setup_finished:
		print("%s already set up" % self)
		return
	
	if !Engine.is_editor_hint():
		print("%s setting up" % self)
		#resetSetup()

func resetSetup() -> void:
	var stop_watch := StopWatch.new()
	stop_watch.measure_msecs("9x9 Grid World Generation")
	await _deleteNodeStructure()
	
	#biome_9x9 = grid.get_9x9_from_array(biomes_data, texture_origin, texture_size.x,texture_size.y)
	
	for x in range(-render_distance, render_distance+1):
		for z in range(-render_distance, render_distance+1):
			_generateNodeStructure(x, z)
	#for x in range(-render_distance, render_distance):
		#for z in range(-render_distance, render_distance):
			#_generateNodeStructure(x, z)
	
	setup_finished = true
	stop_watch.measure_msecs("9x9 Grid World Generation")
	stop_watch.free()
	#print(chunk_data[0])
	#print(chunk_data[2])
	#print(chunk_data[4])
	
	#deleteFoliageInstances(Vector3.ZERO)
	#for i in 2:
		#print(chunk_data[i]) 
	
	#for key in layer_data.keys():
		#print(key)
	#print(layer_data.keys()[0]) ##layername
	#print(layer_data[layer_data.keys()[0]]) ##nodes per layer

func _deleteNodeStructure() -> void:
	##deletes all layer nodes
	layer_data.clear()
	ground_mesh_data.clear()
	chunk_data.clear()
	collision_data.clear()
	for child in get_children():
		for grandchild in child.get_children():
			grandchild.queue_free()
		child.queue_free()
	await get_tree().process_frame

func _generateNodeStructure(x: int,z: int) -> void:
	##GridHelper is base for WorldManager to BiomeTextureData Mapping
	grid = GridHelper.new()
	grid.grid_data = biomes_data
	grid.grid_width = texture_size.x
	grid.grid_height = texture_size.y
	biome_9x9 = grid.get_9x9_from_array(texture_origin) ##world_texture coords
	
	var chunk_position_entry: Array = [Vector3(x,0,z) * size.x]
	var chunk_lods: Array = []
	
	##Generating Floor Mesh
	var mesh_instance := getPartitionMesh(x, z)
	ground_mesh_data.append(mesh_instance)
	
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
			
			##generating new layer and lod nodes
			var layer_node := Node3D.new()
			var layer_data_entry: Array = []
			var static_body_node := StaticBody3D.new()
			var lod_nodes :Array = []
			var layer_name: String = "L%d_%s(%d_%d)" % [res, _mesh_name, x, z]
			
			layer_node.position = Vector3(x,0,z) * size.x
			add_child(layer_node)
			layer_node.set_owner(get_tree().edited_scene_root)
			layer_node.name = layer_name
			
			#generating a static body node for collision
			if _shape:
				layer_node.add_child(static_body_node)
				static_body_node.set_owner(get_tree().edited_scene_root)
			
			for lod in lod_amount:
				#var lod_node := Node3D.new()
				var lod_node := getFoliageMultiMeshInstance(res, lod, _instance_mesh, _scale_range ,_instance_amount, _divide_by_lod,_allowed_biomes, _cast_shadow, _category)
				var lod_name: String = "LOD"+str(lod)+"_"+_mesh_name+"_MultiMeshInstance"
				
				lod_node.name = lod_name
				layer_node.add_child(lod_node)
				lod_node.set_owner(get_tree().edited_scene_root)
				lod_nodes.append(lod_node)
				
				lod_node.biome = biome_9x9[world_to_texture(Vector3(x,0,z))]
				lod_node.generate_instances()
				
				chunk_lods.append(lod_node)
				
				
				#fetching instance_positions from lod-multimesh:
				if _shape and lod == 0:
					var transforms = lod_node.instance_transforms
					for t in transforms:
						var collision = CollisionShape3D.new()
						collision.shape = _shape
						collision.transform = t
						static_body_node.add_child(collision)
						collision.set_owner(get_tree().edited_scene_root)
						collision_data.append(collision)
			
			layer_data_entry.append(layer_node)
			layer_data_entry.append(lod_nodes)
			layer_data[layer_name] = layer_data_entry
			##generating MultiMesh node per lod
	chunk_data.append(chunk_position_entry)
	chunk_data.append(chunk_lods)

func getFoliageMultiMeshInstance(layer: int, lod: int, instance_mesh: Mesh, scale_range: Vector2 ,instance_amount: int, divide_by_lod: bool,  allowed_biomes: PackedInt32Array, shadow: bool = false, category: String = "GRASS") -> Node3D:
	var mmi := FoliageMultiMeshInstance.new() ##custom class
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.use_colors = true
	#mmi.multimesh.mesh = layers[layer]
	mmi.multimesh.mesh = instance_mesh
	
	mmi.category = category
	if debug:
		instance_amount = 0
	mmi.i_count = instance_amount
	mmi.size = size
	mmi.lod = lod
	mmi.max_lod = lod_amount
	mmi.scale_range = scale_range
	mmi.divide = divide_by_lod
	mmi.seed = layer
	mmi.allowed_biomes = allowed_biomes
	
	if not shadow:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	if lod >= (lod_amount - 1) or lod >= 3:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.divide = true
	
	#lod visibility range
	mmi.visibility_range_begin = lod_visibility_step * lod
	mmi.visibility_range_end = lod_visibility_step + (lod_visibility_step * lod)
	return mmi

##this is an example of changing mmi_instances during runtime - use frame cache
#var frame_cache: int = 0
#func _physics_process(delta: float) -> void:
	#if setup_finished:
			#frame_cache += 1
			#if frame_cache == 5:
				#frame_cache = 0
				#deleteFoliageInstances(Vector3.ONE)

## For deleting certain instances in FoliageMultiMeshInstance
## assume collisions are objects, therefore deleting them
var current_chunk: Array
func deleteFoliageInstances(_pos: Vector3, radius: float = 1.1, _collision: CollisionShape3D = null) -> void:
	if !setup_finished:
		return
	var pos_snapped: Vector3
	if _collision:
		pos_snapped = _collision.global_position.snapped(Vector3.ONE * size.x)
		current_chunk = getMultiMeshChunkByPosition(pos_snapped, lod_amount-1)
	else:
		pos_snapped = _pos.snapped(Vector3.ONE * size.x)
		current_chunk = getMultiMeshChunkByPosition(pos_snapped)
	
	if !current_chunk.is_empty():
		for chunk in current_chunk:
			if _collision:
				chunk.cut_static(_pos) ##provisorical
				if collision_data.has(_collision): _collision.queue_free()
			else:
				chunk.cut_grass_around(_pos, radius) ##example for cutting grass around player

func getMultiMeshChunkByPosition(pos: Vector3, include_lod: int = 0) -> Array:
	var multimesh_chunks: Array
	for i in range(0, chunk_data.size(), 2):
		if Vector3(pos.x,0.0, pos.z) == chunk_data[i][0]:
			for lod in chunk_data[i+1]:
				if lod is FoliageMultiMeshInstance && lod.lod <= include_lod:
					multimesh_chunks.append(lod)
	return multimesh_chunks

func getChunkByPosition(pos: Vector3) -> Node3D:
	var chunk: Node3D
	for i in ground_mesh_data:
		if Vector3(pos.x,0.0, pos.z) == i.position:
			chunk = i
	return chunk

func getPartitionMesh(x: int, z: int) -> PartitionMesh3D:
	var partition = PartitionMesh3D.new()
	partition.position = Vector3(x,0,z) * size.x
	partition.mesh = getInstanceMesh(0)
	partition.biome = biome_9x9[world_to_texture(Vector3(x,0,z))]
	#print(partition.biome)
	var mesh_name: String = "M(%d,%d)" % [x, z]
	partition.name = mesh_name
	add_child(partition)
	partition.set_owner(get_tree().edited_scene_root)
	return partition

##TODO: 16 prefab meshes instead
func getInstanceMesh(lod: int) -> PlaneMesh:
	var _mesh := mesh.duplicate()
	_mesh.size = Vector2.ONE * size
	var subdivision_length = pow(2,lod)
	var subdivides = max(size.x/subdivision_length - 1, 0)
	_mesh.subdivide_width = subdivides
	_mesh.subdivide_depth = subdivides
	return _mesh


func _physics_process(delta: float) -> void:
	if player and setup_finished:
		update_player_position()

var position_cache:= Vector3.ZERO ##lokal position snapped
func update_player_position() -> void:
	if player.global_position.snapped(Vector3.ONE * size.x) != position_cache:
		#print("player_position")
		#print(player.global_position.snapped(Vector3.ONE * size.x))
		position_cache = player.global_position.snapped(Vector3.ONE * size.x)
		#print("Player moved Tile - new Center:")
		#print(position_cache)
		#print(getChunkByPosition(position_cache))
		update_tiles(position_cache / size.x)

##TODO: make mesh_classes for biome-id logic. remap tiles to biome pixels
## need translation offset between world_manager grid positions and biome grid positions.
## every update must update meshinstance biomes
func update_tiles(center: Vector3i):
	#print("new center tile:")
	#print(center)
	var stop_watch := StopWatch.new()
	stop_watch.measure_msecs("9x9 Grid World Position Update") ##Positionupdate = 1-3msecs
	
	#biome_9x9 = grid.get_9x9_from_array(biomes_data, texture_origin, texture_size.x,texture_size.y)
	biome_9x9 = grid.get_9x9_from_array(world_to_texture(center))
	for _mesh in ground_mesh_data:
		var tile_coord = Vector3i(
			int(_mesh.global_position.x / size.x),
			0,
			int(_mesh.global_position.z / size.x)
		)
		var offset = tile_coord - center
		if abs(offset.x) > 1:
			offset.x -= sign(offset.x) * 3
		if abs(offset.z) > 1:
			offset.z -= sign(offset.z) * 3
		var new_coord = center + offset
		var biome_pos := world_to_texture(new_coord)
		#print("new coord in texture:")
		#print(biome_pos)
		_mesh.biome = biome_9x9[biome_pos]
		_mesh.global_position = Vector3(new_coord.x * size.x,0,new_coord.z * size.x)
	
	for i in range(0, chunk_data.size(), 2):
		for _layer in chunk_data[i+1]: #children of _layer would be mmi
			#print(_layer)
			var tile_coord = Vector3i(
				int(_layer.global_position.x / size.x),
				0,
				int(_layer.global_position.z / size.x)
			)
			var offset = tile_coord - center
			if abs(offset.x) > 1:
				offset.x -= sign(offset.x) * 3
			if abs(offset.z) > 1:
				offset.z -= sign(offset.z) * 3
			var new_coord = center + offset
			var biome_pos := world_to_texture(new_coord)
			#print(new_coord)
			#print(biome_pos)
			_layer.global_position = Vector3(new_coord.x * size.x,0,new_coord.z * size.x)
			_layer.biome = biome_9x9[biome_pos]
	stop_watch.measure_msecs("9x9 Grid World Position Update") ##Positionupdate = 1-3msecs
	stop_watch.free()

func world_to_texture(local_pos: Vector3) -> Vector2i:
	var px = int(texture_origin.x + local_pos.x * pixels_per_grid)
	var py = int(texture_origin.y + local_pos.z * pixels_per_grid)
	return Vector2i(px, py)

func texture_to_world(pixel: Vector2i) -> Vector3:
	var x = (pixel.x - texture_origin.x) / pixels_per_grid
	var z = (pixel.y - texture_origin.y) / pixels_per_grid
	return Vector3(x, 0, z)

func is_pixel_inside_texture(p: Vector2i) -> bool:
	return (
		p.x >= 0 and p.y >= 0 and
		p.x < texture_size.x and
		p.y < texture_size.y
	)
