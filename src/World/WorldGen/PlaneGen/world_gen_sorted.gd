extends Node3D

## Settings
@export_group("Debug Settings")
@export var debug: bool = false # Enable debug mode for logging, and gizmo rendering
@export var player_character:Node3D # Player character node to be used for navigation and interaction
@export_group("World Generation Settings")
@export var config_file: WorldSheet = WorldSheet.new()
@export var render_distance:int = 2 # Render distance for the world generation in chunks
@export var chunk_overwrite: Resource = null # Resource to overwrite the chunk generation, if any

## Viewport Generation
@onready var viewports: Node = $Viewports
## Collision Generation
@onready var world: StaticBody3D = $World
## Ground Generation
@onready var ground_meshes: Node3D = $GroundMeshes
## Water Generation
@onready var water_meshes: Node3D = $WaterMeshes
## MultiMesh Generation
@onready var multi_meshes: Node3D = $MultiMeshes
## Object Generation
@onready var world_objects: Node3D = $WorldObjects
## Navigation Generation
@onready var navigation: Node3D = $Navigation
## NPC Generation
@onready var npc_s: Node3D = $NPCs

## CONSTANTS
#const WATER = preload("res://src/World/WorldGen/PlaneGen/water_partition.tscn")

## Local Variables
#- Static
@onready var length = ProjectSettings.get_setting("shader_globals/world_partition_length").value
var scheduled_frames: Array = []
var created: bool = false # Flag to check if the world was created successfully
#- Updated
var frame_counter: int = -1000  # Add this at the top with your other variables
var current_chunk: Vector2i = Vector2i.ZERO
var current_mmi_chunk: Vector2i = Vector2i.ZERO
var chunks_to_keep = []
var chunks_to_create = []
var mmi_chunks_to_keep = []
var mmi_chunks_to_create = []
var loaded_chunks: PackedVector2Array = [] # Array to keep track of loaded chunks
var loaded_mmi_chunks: PackedVector2Array = [] # Array to keep track of loaded chunks
var mask_sets: Dictionary = {} # Key(ViewportName): Value(PackedColorArray)

## Performance Settings
@onready var max_phys_threads := OS.get_processor_count() - 1
var active_threads: int = 0
var max_threads: int = 4  # Limit the number of threads

func _ready() -> void:
	if not player_character:
		push_error(self.name+": Player character is not assigned!")
		return
	
	log_debug("Checking hardware capabilities...")
	if max_threads > max_phys_threads: max_threads = max_phys_threads
	max_threads = max_phys_threads
	log_debug("Max threads set to: %d of %d possible threads" % [max_threads, max_phys_threads +1])
	
	## wait for the subviewport to be drawn
	if viewports.get_child_count() > 0:
		log_debug("Waiting for viewports to be ready...")
		await RenderingServer.frame_post_draw
		await load_viewport_textures()
	
	log_debug("Creating World...")
	created = await create_world()
	if not created:
		push_error(self.name+": World creation failed!")
		return

	

	player_character.allow_process = true

func _process(delta: float) -> void:
	if created:
		var player_chunk = Vector2i(
			int(player_character.global_position.x / length),
			int(player_character.global_position.z / length)
		)
		var player_mmi_chunk  = Vector2i(
			int(player_character.global_position.x / (length)),
			int(player_character.global_position.z / (length))
		)
	
		if player_chunk != current_chunk:
			frame_counter = Engine.get_frames_drawn()
			log_debug("Player chunk changed: %s" % player_chunk)
			#update_chunks(player_chunk)
			current_chunk = player_chunk

			# Schedule actions: [delay_in_frames, function_ref]
			scheduled_frames = [
				[0, func(): update_chunks(player_chunk)]
				#[15, func(): update_multi_meshes(player_chunk)]
				#[20, func(): call_func_z()],
			]
		
		# Handle scheduled actions
		if scheduled_frames.size() > 0 and frame_counter >= 0:
			var frames_since = Engine.get_frames_drawn() - frame_counter
			for i in range(scheduled_frames.size() - 1, -1, -1):
				var delay = scheduled_frames[i][0]
				if frames_since >= delay:
					scheduled_frames[i][1].call()
					scheduled_frames.remove_at(i)
		
		if player_mmi_chunk != current_mmi_chunk:
			await get_tree().get_frame()
			log_debug("Player MMI chunk changed: %s" % player_mmi_chunk)
			update_multi_meshes(player_mmi_chunk)
			current_mmi_chunk = player_chunk

	$SubViewport/Camera3D.position.x = player_character.global_position.x
	$SubViewport/Camera3D.position.z = player_character.global_position.z

func load_viewport_textures() -> void:
	# Load textures for each viewport
	log_debug("Loading textures and images from viewports...")
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

				update_viewport_texture(byte_data, viewport.name)

				#log_debug("Loading pixel data for %s..." % viewport.name)
				#var pixel_data = convert_to_packed_color_array(byte_data, true)

func update_viewport_texture(byte_data: PackedByteArray ,viewport_name: String) -> void:
	log_debug("Updating viewport pixel_data for %s..." % viewport_name)
	# Wait until a thread slot is available
	while active_threads >= max_threads:
		await get_tree().process_frame
	# Start a thread for chunk data generation
	var thread = Thread.new()
	active_threads += 1
	thread.start(self._threaded_update_pixel_data.bind(byte_data, viewport_name))

	thread.wait_to_finish()
	active_threads -= 1
	if active_threads == 0:
		log_debug("All Viewport threads finished!")

func _threaded_update_pixel_data(byte_data: PackedByteArray, key: String) -> void:
	log_debug("Thread #%d started for updating pixel data of %s..." % [active_threads+1, key])
	if not byte_data.is_empty():
		log_debug("Loading pixel data for %s..." % key)
		var pixel_data = convert_to_packed_color_array(byte_data, true)
		if pixel_data.is_empty():
			push_error(key+": Pixel data is empty!")
			return
		# Assign the pixel data to Dict with the key
		_store_pixel_data(key, pixel_data)
	else:
		push_error(key+": PackedByteData is missing!")

func _store_pixel_data(mask_name: String, pixel_data: PackedColorArray) -> void:
	if mask_sets.has(mask_name): mask_sets[mask_name] = null  # Clear existing data if any
	mask_sets[mask_name] = pixel_data
	log_debug("Stored pixel data for %s with size: %d" % [mask_name, pixel_data.size()])

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

func create_world() -> bool:
	log_debug("Creating chunks...")
	for x in range(-render_distance, render_distance+1):
		for z in range(-render_distance, render_distance+1):
			populate_chunk(x,z)
	
	log_debug("Creating multi mesh chunks...")
	multi_meshes.grass_mesh_array = config_file.grass_mesh_array
	multi_meshes.lightray_mesh = config_file.lightray_mesh
	for chunk_pos in loaded_chunks:
		populate_multi_meshes(chunk_pos.x, chunk_pos.y)
	
	return true

func populate_chunk(x: int, z: int) -> void:
	add_chunk(x, z, "collision")
	add_chunk(x, z, "ground")
	add_chunk(x, z, "water")

	loaded_chunks.append(Vector2i(x, z))

func add_chunk(x: int, z: int, type: String) -> void:
	match type:
		#"collision":
		#	world.add_chunk(x, z, debug)
		"ground":
			ground_meshes.add_chunk(x, z, debug)
		"water":
			water_meshes.add_chunk(x, z, debug)
		"multi_meshes":
			multi_meshes.add_chunk(x, z)
		_:
			push_error("Unknown chunk type: %s" % type)

func update_chunks(center_chunk: Vector2i) -> void:
	chunks_to_keep = []
	chunks_to_create = []

	# Determine which chunks to keep and which to create
	for x in range(center_chunk.x - render_distance, center_chunk.x + render_distance + 1):
		for z in range(center_chunk.y - render_distance, center_chunk.y + render_distance + 1):
			var chunk_pos = Vector2i(x, z)
			if is_chunk_loaded(chunk_pos, loaded_chunks):
				chunks_to_keep.append(chunk_pos)
			else:
				chunks_to_create.append(chunk_pos)

	loaded_chunks.clear()
	loaded_chunks = chunks_to_keep + chunks_to_create
	#world.update_chunks(chunks_to_keep, chunks_to_create, debug)
	ground_meshes.update_chunks(chunks_to_keep, chunks_to_create, debug)
	water_meshes.update_chunks(chunks_to_keep, chunks_to_create, debug)

func is_chunk_loaded(chunk_pos: Vector2i, _loaded_chunks: PackedVector2Array) -> bool:
	for chunk_position in _loaded_chunks:
		var loaded_chunk_pos = Vector2i(
			int(chunk_position.x),
			int(chunk_position.y)
		)
		if loaded_chunk_pos == chunk_pos:
			return true
	return false


func populate_multi_meshes(x: int, z: int) -> void:
	add_chunk(x, z, "multi_meshes")

func update_multi_meshes(center_chunk: Vector2i) -> void:
	log_debug("Updating multi meshes for chunk: %s" % center_chunk)
	mmi_chunks_to_keep = []
	mmi_chunks_to_create = []

	# Determine which chunks to keep and which to create
	for x in range(center_chunk.x - render_distance, center_chunk.x + render_distance + 1):
		for z in range(center_chunk.y - render_distance, center_chunk.y + render_distance + 1):
			var chunk_pos = Vector2i(x, z)
			if is_chunk_loaded(chunk_pos, loaded_mmi_chunks):
				mmi_chunks_to_keep.append(chunk_pos)
			else:
				mmi_chunks_to_create.append(chunk_pos)

	loaded_mmi_chunks.clear()
	loaded_mmi_chunks = mmi_chunks_to_keep + mmi_chunks_to_create
	multi_meshes.update_chunks(mmi_chunks_to_keep, mmi_chunks_to_create, debug)


## TODO: Implement the following functions
## Use LOD on ground and use groundmeshes as face-reference for collision








func log_debug(message: String, custom_name: String = "") -> void:
	if debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
