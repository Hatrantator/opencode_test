class_name WorldSheet
extends Resource

## Texture Variables
@export var heightmap: Texture
@export var placementmaps: Array[Texture] = []
@export var interactible_objects: Array[String] = ["res://DEMO/Level/custom_multi_mesh_instance_3d.tscn"]
#preload("res://DEMO/Level/custom_multi_mesh_instance_3d.tscn")

## Mesh Variables
@export var grass_mesh_array: Array[Mesh] = []
@export var lightray_mesh: Mesh
@export var placement_mesh_libs: Array[MeshLibrary] = []

func textures_to_dict() -> Dictionary:
    var data: Dictionary = {}
    if heightmap:
       data["heightmap"] = heightmap
    for i in range(placementmaps.size()):
        data["placementmap_%d" % i] = placementmaps[i]
    return data