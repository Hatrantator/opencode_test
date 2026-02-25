#extends MultiMeshInstance3D
#
#func create_multimesh() -> void:
	## Create a single MultiMeshInstance3D for the entire chunk
	#var multimesh_instance = MultiMeshInstance3D.new()
	#var multimesh = MultiMesh.new()
	#multimesh_instance.cast_shadow = 0
	#multimesh.transform_format = MultiMesh.TRANSFORM_3D
	#multimesh.instance_count = highest_cells.size() * instances_per_cluster  # Example: 16 instances per cluster
	#multimesh_instance.multimesh = multimesh
#
	## Assign a mesh to the MultiMesh
	#var mesh = instance_mesh  # Replace with your desired mesh
	#multimesh_instance.multimesh.mesh = mesh
#
	#var mesh_size = mesh.get_aabb().size  # The height of the mesh
	#var cell_size = ground_grid_map.cell_size
#
	## Number of sub-clusters per cell (e.g., 4x4 grid)
	#var sub_cluster_count = int(sqrt(instances_per_cluster))  # Create a square grid of sub-clusters
	#var sub_cluster_size_x = cell_size.x / sub_cluster_count
	#var sub_cluster_size_z = cell_size.z / sub_cluster_count
#
	## Populate the MultiMesh with instances
	#var index = 0
	#for cell_pos in highest_cells.keys():
		#var x = cell_pos.x
		#var z = cell_pos.y
		#var y = (highest_cells[cell_pos] + 1) * cell_size.y
#
		## Adjust the y position to account for the mesh's height
		#y += mesh_size.y# / 2.0  # Center the mesh on top of the cell
#
		## Distribute instances evenly within the cell
		#for sub_x in range(sub_cluster_count):
			#for sub_z in range(sub_cluster_count):
				#if index >= multimesh.instance_count:
					#break
#
				## Calculate the base position of the sub-cluster
				#var base_x = (x * cell_size.x) + (sub_x * sub_cluster_size_x) - (cell_size.x / 2.0) + (sub_cluster_size_x / 2.0)
				#var base_z = (z * cell_size.z) + (sub_z * sub_cluster_size_z) - (cell_size.z / 2.0) + (sub_cluster_size_z / 2.0)
#
				## Add a small random offset within the sub-cluster
				#var offset_x = randf() * (sub_cluster_size_x / 2.0) - (sub_cluster_size_x / 4.0)
				#var offset_z = randf() * (sub_cluster_size_z / 2.0) - (sub_cluster_size_z / 4.0)
#
				#var instance_position = Vector3(
					#base_x + offset_x,  # Position within the sub-cluster's x boundary
					#y,                  # Position adjusted for the mesh height
					#base_z + offset_z   # Position within the sub-cluster's z boundary
				#)
#
				## Set the transform for this instance
				#var transform = Transform3D()
				#transform.origin = instance_position
				#multimesh.set_instance_transform(index, transform)
				#index += 1
#
	## Add the MultiMeshInstance3D to the scene
	#add_child(multimesh_instance)
