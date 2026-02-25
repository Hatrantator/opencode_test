extends MeshInstance3D

var x = 0
var z = 0

## TODO: Implement Material

func _ready() -> void:
	var length = ProjectSettings.get_setting("shader_globals/world_partition_length").value
	name = "ground_chunk(%s,%s)" % [x, z]
	mesh = PlaneMesh.new()
	mesh.size = Vector2.ONE * length
	position = Vector3(x,0,z) * length

	var subdivides = max(length/2 - 1, 0)
	mesh.subdivide_width = subdivides
	mesh.subdivide_depth = subdivides

	mesh.surface_set_material(0, preload("res://src/Resources/Materials/plane_clipmap_material.tres")) 
