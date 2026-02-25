@tool
class_name FoliageResource
extends Resource

@export var mesh_variants: Array[Mesh] = [] ##if more than one Mesh exists, multiple layers will be created
@export var amount: int = 64 ##amount of instances to be created (sum of all mesh variants). example 140k total for 64x64 lush grass.
@export var scale_ranges: PackedVector2Array = [Vector2(1.0,1.0)]
@export var divide_amount_by_lod: bool = true
@export var cast_shadow: bool = false ##only activate shadows when necessary due to performance. to be used for trees or rocks.
@export var collision_variants: Array[Shape3D] = []
#@export var foliage_category: FoliageCategory = FoliageCategory.GRASS
@export_enum("GRASS", "STATIC") var foliage_category: String = "GRASS"
@export var allowed_biomes :PackedInt32Array = [
	0
]
enum FoliageCategory {
	GRASS,
	STATIC
}

func getInstancingData() -> Array:
	var data: Array = []
	var instance_amount: int = roundi(amount / mesh_variants.size())
	var scale_missing_amount = mesh_variants.size() - scale_ranges.size()
	
	if scale_missing_amount > 0:
		for i in scale_missing_amount:
			scale_ranges.append(Vector2(1.0,1.0))
			
	for i in mesh_variants.size():
		var mesh = mesh_variants[i]
		var scale_range = scale_ranges[i]
		var shape: Shape3D = null
		if !collision_variants.is_empty():
			shape = collision_variants[i]
		data.append([mesh, instance_amount, scale_range ,divide_amount_by_lod, cast_shadow, shape, foliage_category, allowed_biomes])
	return data
