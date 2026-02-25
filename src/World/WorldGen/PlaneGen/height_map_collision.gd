extends CollisionShape3D

var image:Image = load(ProjectSettings.get_setting("shader_globals/height_map").value).get_image()
var amplitude:float = ProjectSettings.get_setting("shader_globals/height_amplitude").value

var r_cache: PackedByteArray

var size = image.get_width()

func _ready() -> void:
	image.convert(Image.FORMAT_RF)
	shape.update_map_data_from_image(image, 0, amplitude)
