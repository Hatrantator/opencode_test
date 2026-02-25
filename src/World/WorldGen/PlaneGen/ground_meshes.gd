extends Node3D

const GROUND = preload("res://src/World/WorldGen/PlaneGen/ground_partition.tscn")
@onready var length = ProjectSettings.get_setting("shader_globals/world_partition_length").value

var chunks: Array = []

func add_chunk(x: int, z: int, debug: bool = false) -> void:
	# Create a new collision chunk instance
	var chunk = GROUND.instantiate()
	chunk.x = x
	chunk.z = z
	
	# Add the chunk to the world
	add_child(chunk)
	chunks.append(chunk)
	log_debug("Added ground chunk at position: %s" % chunk.global_position, "",debug)

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
		await get_tree().create_timer(0.1).timeout
	log_debug("Created chunks: %d" % create.size(), "", debug)

func log_debug(message: String, custom_name: String = "", debug: bool = false) -> void:
	if debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
