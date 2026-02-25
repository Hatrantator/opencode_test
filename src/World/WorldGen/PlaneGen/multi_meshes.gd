extends Node3D

const MMI = preload("res://src/World/WorldGen/PlaneGen/multi_mesh_chunk.tscn")

@export var grass_mesh_array: Array[Mesh] 
@export var lightray_mesh: Mesh ## MultiMesh instance mesh

@onready var length = ProjectSettings.get_setting("shader_globals/world_partition_length").value
var chunks: Array = []

func add_chunk(x: int, z: int, debug: bool = false) -> void:
	add_grass(x, z)  # Add grass to the grid
	add_volumetric_light(x, z)  # Add volumetric light to the grid

func update_chunks(keep: Array, create: Array, debug: bool = false) -> void:
	# Free chunks that are outside the render distance
	for chunk in get_children():
		var chunk_pos = Vector2i(
			int(chunk.position.x / length),
			int(chunk.position.z / length)
		)
		if chunk_pos not in keep:
			log_debug("Freeing chunk: %s" % chunk_pos, "",debug)
			chunks.erase(chunk)
			chunk.queue_free()
	
	# Create new chunks
	for chunk_pos in create:
		add_chunk(chunk_pos.x, chunk_pos.y, debug)
		# Wait 0.1 seconds before adding the next node
		await get_tree().create_timer(0.1).timeout
	log_debug("Created chunks: %d" % create.size(), "", debug)

func add_volumetric_light(x: int, z: int) -> void:
	# Add volumetric light to the grid
	create_multimesh( x, z, lightray_mesh, 1, "SUN")  # Create a MultiMesh for the volumetric light

func add_grass(x: int, z: int) -> void:
	# Add grass to the grid
	var multimeshes: Array = []  # Mesh-Array - MultiMeshInstance3D for each Mesh in Array
	for mesh in grass_mesh_array:
		multimeshes.append([mesh, 2])  # Add the mesh to the multimeshes array
	#multimeshes.append([instance_mesh, 20])  # Add the instance mesh to the multimeshes array
	for entry in multimeshes:
		create_multimesh( x, z, entry[0], entry[1], "GRASS")

func create_multimesh(x: int, z: int, i_mesh: Mesh, i_per_cluster: int = 1,  group_name: String = "") -> void:
	var chunk = MMI.instantiate()
	chunk.x = x
	chunk.z = z
	chunk.instance_mesh = i_mesh
	chunk.instances_per_cluster = i_per_cluster
	# Add the chunk to the world
	if group_name != "":
		chunk.group_name = group_name
		log_debug("Added to group: %s" % group_name, "GridMapMultiMesh")
	add_child(chunk)
	chunks.append(chunk)
	log_debug("Added multi mesh chunk at position: %s" % chunk.global_position, "", true)

func log_debug(message: String, custom_name: String = "", debug: bool = false) -> void:
	if debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
