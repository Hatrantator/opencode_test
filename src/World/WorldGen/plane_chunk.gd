extends Node3D

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

var x = 0
var z = 0


var collision: CollisionShape3D = CollisionShape3D.new()

func _ready():
	var length = ProjectSettings.get_setting("shader_globals/world_partition_length").value
	#mesh_instance_3d.mesh = PlaneMesh.new()
	mesh_instance_3d.mesh.size = Vector2.ONE * length + Vector2(0.01,0.01)
	position = Vector3(x,0,z) * length

	mesh_instance_3d.create_convex_collision()
