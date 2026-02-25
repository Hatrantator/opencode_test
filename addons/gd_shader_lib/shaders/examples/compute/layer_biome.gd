#@tool
extends Node

##TODO:
#Put this under/into world_manager

##Takes in 3 ValueTextures and returns BiomeTexture and BiomesDataFloat32Array
#@export_tool_button("Create", "Bake") var btn_crt = self.execute_biome_compute
@export var hash := "ABC"
@export var temperature: Texture2D
@export var humidity: Texture2D
@export var height: Texture2D
@export var biome_texture: Texture2D
@onready var texture_rect: TextureRect = $TextureRect
@onready var world_manager: WorldManager = $SubViewportContainer/SubViewport/WorldManager

func _ready() -> void:
	if temperature is NoiseTexture2D: await temperature.changed
	if humidity is NoiseTexture2D: await humidity.changed
	if height is NoiseTexture2D: await height.changed
	execute_biome_compute()

func execute_biome_compute() -> void:
	var stop_watch := StopWatch.new()
	stop_watch.measure_msecs("layer biome execution total")
	stop_watch.measure_msecs("layer biome compute execution")
	
	var compute_shader := ComputeHelper.create('res://addons/gd_shader_lib/shaders/examples/compute/layer_biome.compute.glsl')
	
	var temperature_image := temperature.get_image()
	temperature_image.convert(Image.FORMAT_RGBA8)
	var temperature_in_texture := ImageUniform.create(temperature_image)
	
	var humidity_image := humidity.get_image()
	humidity_image.convert(Image.FORMAT_RGBA8)
	var humidity_in_texture := ImageUniform.create(humidity_image)
	
	var height_image := height.get_image()
	height_image.convert(Image.FORMAT_RGBA8)
	var height_in_texture := ImageUniform.create(height_image)
	
	var biome_image := Image.create(temperature_image.get_width(), temperature_image.get_height(), false, Image.FORMAT_RGBAF)
	biome_image.convert(Image.FORMAT_RGBAF)
	var biome_in_texture := ImageUniform.create(biome_image)
	var biome_out_texture := SharedImageUniform.create(biome_in_texture)
	
	var fbiome := PackedFloat32Array()
	fbiome.resize(temperature_image.get_width()*temperature_image.get_height())
	var fbiome_byte = fbiome.to_byte_array()
	var biomes := StorageBufferUniform.create(fbiome_byte)
	
	compute_shader.add_uniform_array([temperature_in_texture,humidity_in_texture,height_in_texture,biome_in_texture,biome_out_texture, biomes])
	var work_groups := Vector3i(temperature_image.get_width(),temperature_image.get_height(),1)
	compute_shader.run(work_groups)
	ComputeHelper.sync()
	
	stop_watch.measure_msecs("layer biome compute execution")
	stop_watch.measure_msecs("layer biome ssbo cpu read")
	
	var biomes_data := biomes.get_data().to_float32_array()
	stop_watch.measure_msecs("layer biome ssbo cpu read")
	#print(biomes_data.size())
	
	stop_watch.measure_msecs("layer biome image cpu read")
	var new_img = biome_out_texture.get_image()
	#print(new_img.get_size())
	biome_image.convert(Image.FORMAT_RGBAF)
	new_img.save_png("res://addons/gd_shader_lib/shaders/examples/compute/output/layer_biome_out.png")
	var new_tex = ImageTexture.create_from_image(new_img)
	texture_rect.texture = new_tex
	biome_texture = new_tex
	stop_watch.measure_msecs("layer biome image cpu read")
	stop_watch.measure_msecs("layer biome execution total")
	
	
	#var grid := GridHelper.new()
	#grid.grid_data = biomes_data
	#grid.grid_width = temperature_image.get_width()
	#grid.grid_height = temperature_image.get_height()
	#var biome_9x9 := grid.get_9x9_from_array(Vector2i(2,504))
	#print(biome_9x9)
	
	generate_world(biomes_data)
	stop_watch.measure_msecs("9x9 Grid World Generation")
	stop_watch.free()
	

func generate_world(data: PackedFloat32Array) -> void:
	world_manager.biomes_data = data
	await world_manager.resetSetup()
