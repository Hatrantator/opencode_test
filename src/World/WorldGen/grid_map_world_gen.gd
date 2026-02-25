#@tool
extends Node3D

## Creates the whole World!
#@export_tool_button("Build World") var build_world = self.create_chunks

## Settings
@export var debug: bool = false
@export var player_character:Node3D
@export var grid_map: GridMap
@export var render_distance:int = 2

## Clipmap
@export var config: WorldSheet = WorldSheet.new()
@export var heightmap: Texture
@export var placementmap: Texture
@export var chunk_max_height: int = 12 ## maximum block Y position steps: max_depth + max_height = amount of Y steps
@export var chunk_max_depth: int = -4 ## lowest block Y position

@onready var objects: Node3D = $Objects

## Viewport Clipmaps
@onready var viewports: Node = $Viewports

## Locals
const MAP_CHUNK = preload("res://src/World/WorldGen/grid_map_chunk.tscn")
@onready var height_img: Image
@onready var placement_img: Image

## main references for GridMap & MultiMeshInstance3D
var img_width: int = 0
var mask_sets: Dictionary = {} # Key: PackedColorArray
var height_data: PackedColorArray = []
var placement_data: Array[PackedColorArray] = []

## Process Threads
var active_threads: int = 0
#@onready var max_threads := OS.get_processor_count() - 1
var max_threads: int = 20  # Limit the number of threads

## globals
@onready var length = ProjectSettings.get_setting("shader_globals/world_partition_length").value
var current_chunk: Vector2i = Vector2i.ZERO

func _process(delta: float) -> void:
	var player_chunk = Vector2i(
		int(player_character.global_position.x / length),
		int(player_character.global_position.z / length)
	)
	
	if player_chunk != current_chunk:
		log_debug("Player chunk changed: %s" % player_chunk)
		update_chunks(player_chunk)
		current_chunk = player_chunk
	$SubViewport/Camera3D.position.x = player_character.global_position.x
	$SubViewport/Camera3D.position.z = player_character.global_position.z



func _ready() -> void:
	if not player_character:
		push_error(self.name+": Player character is not assigned!")
		return
	
	## wait for the subviewport to be drawn
	await RenderingServer.frame_post_draw
	await load_viewport_textures()
	create_chunks()


func load_viewport_textures() -> void:
	# Load textures for each viewport
	log_debug("Loading textures and images for viewports...")
	for viewport in viewports.get_children():
		if viewport is Viewport:
			# waiting for the viewport.child.texture to be ready
			var texture = viewport.get_texture()
			if texture:
				## here we can set the global mask_shader_param
				if viewport.name == "GroundMask":
					RenderingServer.global_shader_parameter_set("ground_mask", texture)
				
				var _img = texture.get_image()
				if not _img:
					push_error(viewport.name+": Image is missing!")
					return
				_img.convert(Image.FORMAT_RGBA8)

				log_debug("Loading image data for %s..." % viewport.name)
				var byte_data = _img.get_data()

				log_debug("Loading pixel data for %s..." % viewport.name)
				var pixel_data = convert_to_packed_color_array(byte_data, true)

				if pixel_data.size() == 0:
					push_error(viewport.name+": Pixel data is empty!")
					return

				# Assign the pixel data to Dict with the key
				mask_sets[viewport.name] = pixel_data
				log_debug("Pixel data size: %d" % pixel_data.size())


func update_chunks(center_chunk: Vector2i) -> void:
	var chunks_to_keep = []
	var chunks_to_create = []

	# Determine which chunks to keep and which to create
	for x in range(center_chunk.x - render_distance, center_chunk.x + render_distance + 1):
		for z in range(center_chunk.y - render_distance, center_chunk.y + render_distance + 1):
			var chunk_pos = Vector2i(x, z)
			if is_chunk_loaded(chunk_pos):
				chunks_to_keep.append(chunk_pos)
			else:
				chunks_to_create.append(chunk_pos)

	# Free chunks that are outside the render distance
	for chunk in get_children():
		if chunk.name.begins_with("chunk_"):
			var chunk_pos = Vector2i(
				int(chunk.position.x / length),
				int(chunk.position.z / length)
			)
			if chunk_pos not in chunks_to_keep:
				log_debug("Freeing chunk: %s" % chunk_pos)
				chunk.queue_free()

	# Create new chunks
	for chunk_pos in chunks_to_create:
		log_debug("Creating chunk: %s" % chunk_pos)
		populate_chunk(chunk_pos.x, chunk_pos.y)


func is_chunk_loaded(chunk_pos: Vector2i) -> bool:
	for chunk in get_children():
		if chunk.name.begins_with("chunk_"):
			var loaded_chunk_pos = Vector2i(
				int(chunk.position.x / length),
				int(chunk.position.z / length)
		)
			if loaded_chunk_pos == chunk_pos:
				return true
	return false


func create_chunks() -> void:
	log_debug("Assigning images...")
	# we iterate over textures in an array and call generate_pixel_data for each
	var config_textures = config.textures_to_dict()
	for key in config_textures.keys():
		generate_pixel_data(key, config_textures[key])


	#load_pixel_data() #TODO: Delete this function
	log_debug("Creating chunks...")
	for x in range(-render_distance, render_distance+1):
		for z in range(-render_distance, render_distance+1):
			populate_chunk(x,z)
	
	# Wait for all threads to finish
	while active_threads > 0:
		await get_tree().process_frame
		log_debug("Waiting for threads to finish...")
	# All threads finished
	player_character.allow_process = true

## NO FRIGGIN MIPMAPS ALLOWED!!!
func generate_pixel_data(key: String, tex: Texture) -> void:
	log_debug("Generating pixel data for %s..." % key)
	load_pixel_data_to_dict(key, tex)


func load_pixel_data_to_dict(key: String, tex: Texture) -> void:
	if not tex:
		push_error(key + ": Texture is not assigned!")
		return
	
	var _img = tex.get_image()
	if not _img:
		push_error(key+": Image is missing!")
		return
	img_width = _img.get_width()
	_img.convert(Image.FORMAT_RGBA8)
	log_debug("Image format: %d" % _img.get_format())
	
	log_debug("Loading image data for %s..." % key)
	var byte_data = _img.get_data()

	log_debug("Loading pixel data for %s..." % key)
	var pixel_data = convert_to_packed_color_array(byte_data, true)
	if pixel_data.size() == 0:
		push_error(key+": Pixel data is empty!")
		return

	# Assign the pixel data to Dict with the key
	if key == "heightmap":
		height_data = pixel_data
	elif key.begins_with("placementmap_"):
		placement_data.append(pixel_data)

	log_debug("Pixel data size: %d" % pixel_data.size())

## Deprecated function
func load_pixel_data() -> void:
	log_debug("Assigning images...")
	if not heightmap or not placementmap:
		push_error(self.name + ": Heightmap or placementmap is not assigned!")
		return

	# no Mipmaps allowed!!!
	height_img = heightmap.get_image()
	placement_img = placementmap.get_image()
	if not height_img or not placement_img:
		push_error(self.name+": One or more images are missing!")
		return

	# ensure the images are in RGBA format
	height_img.convert(Image.FORMAT_RGBA8)
	placement_img.convert(Image.FORMAT_RGBA8)
	log_debug("Heightmap format: %d" % height_img.get_format())
	log_debug("Placementmap format: %d" % placement_img.get_format())

	log_debug("Loading image data...")
	var height_byte_data = height_img.get_data()
	var placement_byte_data = placement_img.get_data()

	# Convert PackedByteArray to PackedColorArray - RGBA8 has alpha
	log_debug("Loading pixel data...")
	height_data = convert_to_packed_color_array(height_byte_data, true)
	placement_data = convert_to_packed_color_array(placement_byte_data, true)

	if height_data.size() == 0 or placement_data.size() == 0:
		push_error(self.name+": Pixel data is empty!")
		return
	log_debug("Pixel data loaded successfully!")
	log_debug("Height data size: %d" % height_data.size())
	log_debug("Placement data size: %d" % placement_data.size())


func populate_chunk(x: int, z: int) -> void:
	# Wait until a thread slot is available
	while active_threads >= max_threads:
		await get_tree().process_frame
	# Start a thread for chunk data generation
	var thread = Thread.new()
	active_threads += 1
	thread.start(self._threaded_generate_chunk.bind([x, z]))

	thread.wait_to_finish()
	active_threads -= 1
	if active_threads == 0:
		log_debug("All threads finished!")

# Threaded function to generate chunk data
func _threaded_generate_chunk(args: Array) -> void:
	var x = args[0]
	var z = args[1]
	var gridmap_values = get_gridmap_values(x, z)

	# Pass the result back to the main thread
	call_deferred("_apply_chunk_data", x, z, gridmap_values)

	# Clean up the thread
	#active_threads -= 1
	#if active_threads == 0:
	#	log_debug("All threads finished!")

# Main thread function to apply chunk data
func _apply_chunk_data(x: int, z: int, gridmap_values: Array) -> void:
	var chunk = MAP_CHUNK.instantiate()
	chunk.position = Vector3(x * length, 0, z * length)
	chunk.name = "chunk_(%d,%d)" % [x, z]
	chunk.debug = debug

	# Set the gridmap cells and heights
	chunk.gridmap_cells = gridmap_values[0]
	chunk.gridmap_heights = gridmap_values[1]
	chunk.object_cells = gridmap_values[2]
	chunk.masks = gridmap_values[3]

	# Set the world_config data
	chunk.placement_mesh_libs = config.placement_mesh_libs
	chunk.grass_mesh_array = config.grass_mesh_array
	chunk.lightray_mesh = config.lightray_mesh
	add_child(chunk)

	log_debug("Chunk (%d, %d) added to the scene." % [x, z])

## iterates over gridmap cells and set the pixel data sets for the chunk
#func get_gridmap_values(x: int, z: int) -> Array:
#	log_debug("Creating gridmap data", "Chunk(%d, %d)" % [x, z])
#	var chunk_values :Array = []
#	var chunk_cells :PackedVector3Array = []
#	var chunk_heights :Array = []
#	var chunk_objects :Array[PackedVector3Array] = []
#	var chunk_masks :Dictionary = {}
#	
#	# Calculate the gridmap size (number of cells in the chunk)
#	var cell_size := 2  # Each cell corresponds to a 2x2 area in the height image
#	var gridmap_size = int(length / cell_size)
#
#	# Iterate over the gridmap cells
#	for gx in range(gridmap_size):
#		for gz in range(gridmap_size):
#			# Calculate the corresponding pixel position in the height image
#			var pixel_x = x * gridmap_size + gx
#			var pixel_z = z * gridmap_size + gz
#
#			# Ensure the pixel position is within bounds
#			if pixel_x < 0 or pixel_x >= img_width or pixel_z < 0 or pixel_z >= img_width:
#				continue
#
#
#			# Get the color data from the pixel_data array
#			var pixel_index = pixel_z * img_width + pixel_x
#			if pixel_index >= 0 and pixel_index < (img_width * img_width):
#
#
#				# Convert the color to a height value
#				var color = height_data[pixel_index]
#				var height_value = color_to_height(color)
#
#				# Get Mask Pixel Color values
#				var mask_color: Color
#				for key in mask_sets.keys():
#					if not chunk_masks.has(key):
#						chunk_masks[key] = PackedColorArray()
#					var mask_data = mask_sets[key]
#					mask_color = mask_data[pixel_index]
#					#if mask_color != Color.BLACK:
#					#	log_debug("Mask color: %s" % mask_color, "Chunk(%d, %d)" % [x, z])
#					chunk_masks[key].append(mask_color) # Add the mask color to the chunk_masks array
#				
#				var placement_color: Color
#				for i in placement_data.size():
#					if chunk_objects.size() < i+1:
#						chunk_objects.append(PackedVector3Array())
#					placement_color = placement_data[i][pixel_index]
#
#					# Check if pixel is set and add an object cell
#					# TODO: different object types based on color
#					if placement_color == Color.WHITE:
#						chunk_objects[i].append(Vector3i(gx, height_value, gz)) # Add the object cell to the chunk_objects array
#				
#
#				if height_value == chunk_max_depth:
#					chunk_cells.append(Vector3i(gx, height_value, gz))
#				else:
#					for height in range(chunk_max_depth, height_value):
#						chunk_cells.append(Vector3i(gx, height, gz)) # Add the cell to the chunk_cells array
#				chunk_heights.append(height_value) # Add the height value to the chunk_heights array
#
#	chunk_values.append(chunk_cells) # Add the chunk_cells array to the chunk_values array
#	chunk_values.append(chunk_heights) # Add the chunk_heights array to the chunk_values array
#	chunk_values.append(chunk_objects) # Add the chunk_objects array to the chunk_values array
#	chunk_values.append(chunk_masks) # Add the chunk_masks array to the chunk_values array
#
#	log_debug("Chunk cells size: %d" % chunk_cells.size(), "Chunk(%d, %d)" % [x, z])
#	log_debug("Chunk heights size: %d" % chunk_heights.size(),"Chunk(%d, %d)" % [x, z])
#	log_debug("Chunk objects size: %d" % chunk_objects.size(), "Chunk(%d, %d)" % [x, z])
#	log_debug("Chunk masks size: %d" % chunk_masks.size(), "Chunk(%d, %d)" % [x, z])
#	for key in chunk_masks.keys():
#		log_debug("Chunk mask %s size: %d" % [key, chunk_masks[key].size()], "Chunk(%d, %d)" % [x, z])
#
#	return chunk_values

func get_gridmap_values(x: int, z: int) -> Array:
	var chunk_values :Array = []
	var chunk_cells :PackedVector3Array = []
	var chunk_heights :Array = []
	var chunk_objects :Array[PackedVector3Array] = []
	var chunk_masks :Dictionary = {}

	var cell_size := 2
	var gridmap_size = int(length / cell_size)
	var chunk_pixel_origin_x = x * gridmap_size
	var chunk_pixel_origin_z = z * gridmap_size
	var img_area = img_width * img_width

	# Cache mask_sets and placement_data
	var mask_keys = mask_sets.keys()
	var mask_arrays = []
	for key in mask_keys:
		mask_arrays.append(mask_sets[key])

	# Preallocate chunk_objects arrays for each placement map
	for i in placement_data.size():
		chunk_objects.append(PackedVector3Array())

	for gx in range(gridmap_size):
		for gz in range(gridmap_size):
			var pixel_x = chunk_pixel_origin_x + gx
			var pixel_z = chunk_pixel_origin_z + gz
			if pixel_x < 0 or pixel_x >= img_width or pixel_z < 0 or pixel_z >= img_width:
				continue
			var pixel_index = pixel_z * img_width + pixel_x
			if pixel_index < 0 or pixel_index >= img_area:
				continue

			var color = height_data[pixel_index]
			var height_value = color_to_height(color)

			# Masks
			for i in mask_keys.size():
				var key = mask_keys[i]
				if not chunk_masks.has(key):
					chunk_masks[key] = PackedColorArray()
				chunk_masks[key].append(mask_arrays[i][pixel_index])

			# Batch placement: process all placement maps in one pass
			for i in placement_data.size():
				var placement_color = placement_data[i][pixel_index]
				if placement_color == Color.WHITE:
					chunk_objects[i].append(Vector3i(gx, height_value, gz))

			# Cells
			if height_value == chunk_max_depth:
				chunk_cells.append(Vector3i(gx, height_value, gz))
			else:
				for height in range(chunk_max_depth, height_value):
					chunk_cells.append(Vector3i(gx, height, gz))
			chunk_heights.append(height_value)

	chunk_values.append(chunk_cells)
	chunk_values.append(chunk_heights)
	chunk_values.append(chunk_objects)
	chunk_values.append(chunk_masks)
	return chunk_values

func convert_to_packed_color_array(byte_array: PackedByteArray, has_alpha: bool = false) -> PackedColorArray:
	log_debug("PackedByteArray size: %d" % byte_array.size())
	var color_array = PackedColorArray()
	var step = 4 if has_alpha else 3  # 4 bytes per pixel if alpha is included, otherwise 3

	# Check if the byte array size is valid
	if byte_array.size() % step != 0:
		log_debug("PackedByteArray size is not divisible by step (%d). Size: %d" % [step, byte_array.size()])

	for i in range(0, byte_array.size() - step + 1, step):
		var r = byte_array[i] / 255.0
		var g = byte_array[i + 1] / 255.0
		var b = byte_array[i + 2] / 255.0
		var a = byte_array[i + 3] / 255.0 if has_alpha else 1.0
		color_array.append(Color(r, g, b, a))

	return color_array


func color_to_height(color: Color) -> int:
	var height_divisor = 256 / chunk_max_height
	var height = round(color.r8 / height_divisor) + chunk_max_depth
	return height


func log_debug(message: String, custom_name: String = "") -> void:
	if debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
