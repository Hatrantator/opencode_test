@tool
extends MeshInstance3D
class_name PartitionMesh3D

@export var biome = 0
#TODO: move this to a biome resource - make several palettes for different things; eg: grass0-grass4, rock0-rock4, etc.
@export var BIOMECOLORS :PackedColorArray = [
	Color(0.0, 0.25, 0.6, 1.0),
	Color(0.7, 0.8, 0.7, 1.0),
	Color(0.3, 0.5, 0.3, 1.0),
	Color(0.8, 0.9, 0.9, 1.0),
	Color(0.196, 0.357, 0.094, 1.0),
	Color(0.1, 0.5, 0.1, 1.0),
	Color(0.0, 0.4, 0.2, 1.0),
	Color(0.9, 0.8, 0.4, 1.0),
	Color(0.7, 0.7, 0.3, 1.0),
	Color(0.0, 0.6, 0.3, 1.0),
	Color(0.5, 0.5, 0.5, 1.0),
	Color(1.0, 1.0, 1.0, 1.0),
	Color(0.85, 0.95, 1.0, 1.0)
]

var biome_cache = 0

func _update_biome() -> void:
	print("update_biome to: %s" % biome)
	change_override_material()
	biome_cache = biome

func _process(delta: float) -> void:
	if biome:
		if biome != biome_cache:
			_update_biome()
		
func change_override_material() -> void:
	print("change_material: %s" % BIOMECOLORS[biome as int])
	var mat := get_active_material(0)
	if not mat: mat = StandardMaterial3D.new()
	if mat is StandardMaterial3D:
		mat = mat.duplicate()
		set_surface_override_material(0, mat)
		mat.albedo_color = BIOMECOLORS[biome as int] # Rot
	else:
		mat = mat.duplicate()
		set_surface_override_material(0, mat)
		mat.set_shader_parameter("flat_color", BIOMECOLORS[biome as int])
