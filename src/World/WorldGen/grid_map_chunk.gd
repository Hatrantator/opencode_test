class_name GridMapChunk
extends Node3D


@onready var ground_grid_map: GridMap = $GroundGridMap
@onready var object_grid_maps: Node3D = $ObjectGridMaps
@onready var interactable_objects: Node3D = $InteractableObjects
var int_obj_array: Array = []

var debug: bool = false
@export var gridmap_cells: PackedVector3Array = []
@export var object_cells: Array[PackedVector3Array] = []
@export var masks: Dictionary = {}
@export var placement_mesh_libs: Array[MeshLibrary] = []
@export var gridmap_heights: PackedInt32Array = []

## MultiMesh Variables
var highest_cells: Dictionary = {}
#	@export var instances_per_cluster: int = 10  # Number of MulitMesh instances per cluster
@export var grass_mesh_array: Array[Mesh] 
@export var lightray_mesh: Mesh ## MultiMesh instance mesh

func _ready() -> void:
#	if gridmap_heights.size() > 0:
#		var heights: Array = Array(gridmap_heights)
#		log_debug("Min height: %d, Max height: %d" % [heights.min(), heights.max()])
	get_instance_values()
	create_chunk()

func create_chunk() -> void:
	log_debug("Creating chunk at position: %s" % position)
	# Populate the chunk with gridmap cells and heights
	for cell in gridmap_cells:
		# Set the cell item to 0 (ground tile)
		ground_grid_map.set_cell_item(Vector3i(cell), 0)  # Set the cell item to 0 (ground tile)
		# Find the highest cell for each (x, z) position
		var x = cell.x + 0.5
		var z = cell.z + 0.5
		var y = cell.y
		# Update the highest cell for this (x, z) position
		if not highest_cells.has(Vector2(x, z)) or highest_cells[Vector2(x, z)] < y:
			highest_cells[Vector2(x, z)] = y

	for i in object_cells.size():
		create_gridmap(i, object_cells[i])
#		var array: PackedVector3Array = object_cells[i]
#		for object in array:
#			# Set the object cell item to 1 (object tile)
#			object_grid_map.set_cell_item(Vector3i(object), 0)  # Set the cell item to 1 (object tile)
	log_debug("Highest cells size: %s" % highest_cells.keys().size())
	# adding the gridmap multimeshes
	add_grass()
	add_volumetric_light()

func get_instance_values() -> Dictionary:
	var instance_dict :Dictionary = {} ## Vector2 = highest cell, 
	var mask_colors :PackedVector3Array = []
	## In here we calculcate data for instancing multimeshes and objects
	# Populate the chunk with gridmap cells and heights
	print("gridmap_cells @ %s, size = %d" % [name, gridmap_cells.size()])
	for cell in gridmap_cells:
		# Set the cell item to 0 (ground tile)
		ground_grid_map.set_cell_item(Vector3i(cell), 0)  # Set the cell item to 0 (ground tile)

		# Find the highest cell for each (x, z) position
		var x = cell.x + 0.5
		var z = cell.z + 0.5
		var y = cell.y

		# Update the highest cell for this (x, z) position
		if not instance_dict.has(Vector2(x, z)) or instance_dict[Vector2(x, z)] < y:
			instance_dict[Vector2(x, z)] = y

	## TODO FIX THIS, DO NOT USE WHOLE CELLS FOR THIS
	# this is always the same size as the mask
	#var i_cell = 0
	#for cell in instance_dict.keys():
	#	var allow = true
	#	if masks.has("GroundMask") && self.is_in_group("GRASS"):
	#		var mask_array = masks["GroundMask"]
	#		var mask_color: Color = mask_array[i_cell]
	#		if mask_color != Color.BLACK:
	#			allow = mask_array[i_cell].r >= ground_mask_bw_threshold
	#		else: allow = false
#
	#	if allow:
	#		# calculate the base position of the cell		
	#		var x = cell_pos.x
	#		var z = cell_pos.y
	#		var y = (highest_cells[cell_pos] + 1) * cell_size.y  # Base position on top of the cell
#
#
	#		# Adjust the y position to account for the mesh's height
	#		y += mesh_height / 2  # Center the mesh on top of the cell
	#		cell_pos_array.append(Vector3(x, y, z))
	#	i_cell += 1

	return instance_dict

func create_gridmap(i: int, object_array: PackedVector3Array) -> void:
	# Create the gridmap
	var grid_map = GridMap.new()
	grid_map.name = "ObjectGridMap_%s" % i
	grid_map.cell_size = ground_grid_map.cell_size  # Set the cell size to match the ground grid map
	grid_map.mesh_library = placement_mesh_libs[i]  # Set the mesh library
	object_grid_maps.add_child(grid_map)  # Add the gridmap to the object gridmaps node
	add_objects(grid_map, object_array)  # Add objects to the gridmap
	log_debug("Adding objects %s to gridmap: %s" % [grid_map.mesh_library,grid_map.name])

func add_objects(gm: GridMap, object_array: PackedVector3Array) -> void:
	var rotation_array: Array = [0,10,16,22]
	# Add objects to the grid
	for object in object_array:
	#	if gm.mesh_library.get_meshes().size() >= 12:
	#		gm.set_cell_item(Vector3i(object), randi_range(8,11))  # Set the cell item to 0 (object tile)
	#	else:
		var id = 0
		gm.set_cell_item(Vector3i(object), 0, rotation_array[randi() % 4])  # Set the cell item to 0 (object tile)
		add_interactable_objects(gm, object, id)  # Add interactable objects to the gridmap

func add_interactable_objects(gm: GridMap, object_pos: Vector3, parent_id: int) -> void:
	# Add interactable objects to the grid
	var scene = preload("res://src/Environment/Objects/pickable_object.tscn")
	var instance = scene.instantiate()
	# --- Circular random offset ---
	var min_spread = 1.0
	var max_spread = 3.0
	var angle = randf() * TAU  # TAU = 2 * PI
	var distance = lerp(min_spread, max_spread, randf())
	var offset_x = cos(angle) * distance
	var offset_z = sin(angle) * distance
	instance.global_position = gm.map_to_local(object_pos) + Vector3(offset_x, 2, offset_z)
	# ---
	get_parent().objects.add_child(instance)  # Add the instance to the parent objects node
	#interactable_objects.add_child(instance)  # Add the instance to the interactable objects node
	int_obj_array.append(instance)  # Add the instance to the interactable objects array
	## TODO: add Autoload object manager to keep track of objects
	log_debug("Adding interactable object %s @: %s" % [instance, instance.position])

func add_grass() -> void:
	# Add grass to the grid
	var multimeshes: Array = []  # Mesh-Array - MultiMeshInstance3D for each Mesh in Array
	for mesh in grass_mesh_array:
		multimeshes.append([mesh, 8])  # Add the mesh to the multimeshes array
	#multimeshes.append([instance_mesh, 20])  # Add the instance mesh to the multimeshes array
	for entry in multimeshes:
		grid_map_multimesh(entry[0], entry[1], "GRASS")   # Create a MultiMesh for each entry in the multimeshes array
		#create_multimesh(entry[0], entry[1])

func add_volumetric_light() -> void:
	# Add volumetric light to the grid
	grid_map_multimesh(lightray_mesh, 1, "SUN")  # Create a MultiMesh for the volumetric light

func grid_map_multimesh(i_mesh: Mesh, i_per_cluster: int = 1, group_name: String = "") -> void:
	var multimesh_instance = GridMapMultiMesh.new()
	multimesh_instance.instance_mesh = i_mesh
	multimesh_instance.instances_per_cluster = i_per_cluster

	multimesh_instance.cell_size = ground_grid_map.cell_size
	multimesh_instance.highest_cells = highest_cells
	multimesh_instance.masks = masks
	if group_name != "":
		multimesh_instance.group_name = group_name
		log_debug("Added to group: %s" % group_name, "GridMapMultiMesh")
	
	add_child(multimesh_instance)

## DEPRECATED
func update_multimesh(group: String) -> void:
	for child in get_children():
		if child is GridMapMultiMesh && child.is_in_group(group):
			print("Updating")

## DEPRECATED
func create_multimesh(i_mesh: Mesh, instances_per_cluster: int) -> void:
	# Create a single MultiMeshInstance3D for the entire chunk
	var multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = highest_cells.size() * instances_per_cluster  # Example: 16 instances per cluster
	multimesh_instance.multimesh = multimesh

	# Assign a mesh to the MultiMesh
	var mesh = i_mesh  # Replace with your desired mesh
	multimesh_instance.multimesh.mesh = mesh

	# Get the mesh's height using its AABB
	var mesh_aabb = mesh.get_aabb()
	var mesh_height = mesh_aabb.size.y  # The height of the mesh

	var cell_size = ground_grid_map.cell_size

	# Populate the MultiMesh with instances
	var index = 0
	for cell_pos in highest_cells.keys():
		var x = cell_pos.x
		var z = cell_pos.y
		var y = (highest_cells[cell_pos] + 1) * cell_size.y  # Base position on top of the cell

		# Adjust the y position to account for the mesh's height
		y += mesh_height / 2  # Center the mesh on top of the cell

		# Distribute instances within the boundaries of the cell
		for cluster_index in range(instances_per_cluster):  # Example: 16 instances per cluster
			# Calculate the position within the cell boundaries
			var offset_x = randf() * cell_size.x - (cell_size.x / 2.0)  # Random offset within the cell's x boundary
			var offset_z = randf() * cell_size.z - (cell_size.z / 2.0)  # Random offset within the cell's z boundary
			var instance_position = Vector3(
				(x * cell_size.x) + offset_x,  # Position within the x boundary
				y,                             # Position adjusted for the mesh height
				(z * cell_size.z) + offset_z   # Position within the z boundary
			)

			# Set the transform for this instance
			var trans = Transform3D()
			trans.origin = instance_position
			#var custom_data = Color(instance_position.x, instance_position.y, instance_position.z, 1.0)  # Example custom data
			#multimesh.set_instance_custom_data(index, custom_data)
			multimesh.set_instance_transform(index, trans)
			index += 1
	# Add the MultiMeshInstance3D to the scene
	add_child(multimesh_instance)

func log_debug(message: String, custom_name: String = "") -> void:
	if debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
