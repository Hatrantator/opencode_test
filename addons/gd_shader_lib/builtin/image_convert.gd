extends Object
class_name ImageConverter

static func save_file(img: Image, path: String) -> void:
	img.save_png(path)
