extends Node

var image:Image = load(ProjectSettings.get_setting("shader_globals/height_map").value).get_image()
var amplitude:float = ProjectSettings.get_setting("shader_globals/height_amplitude").value

var r_cache: PackedByteArray

var size = image.get_width()

#func get_height(x,z):
#	return image.get_pixel(fposmod(x,size), fposmod(z,size)).r * amplitude

func _ready() -> void:
	if not image:
		push_error("Heightmap image is not set or could not be loaded.")
		return
	update_image_r_cache(image)

func update_image_r_cache(image: Image) -> void:
	r_cache = PackedByteArray()
	r_cache.resize(size * size)

	for y in range(size):
		for x in range(size):
			var color = image.get_pixel(x, y)
			var r = int(color.r)
			r_cache[y * size + x] = r

func get_height(x: int, z: int) -> int:
	if r_cache.is_empty():
		print("NO HEIGHT CACHE")
		return 0  # Return 0 if the cache is not initialized
	return r_cache[fposmod(z,size) * size + fposmod(x,size)] * amplitude
