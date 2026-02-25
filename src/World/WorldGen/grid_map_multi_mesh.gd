class_name GridMapMultiMesh
extends MultiMeshInstance3D

@export var instance_mesh: Mesh # MultiMesh instance mesh
@export var instances_per_cluster: int = 1  # Number of MultiMesh instances per cluster
@export var cell_size: Vector3 = Vector3(1, 1, 1) # Size of each cell in the grid map
@export var highest_cells: Dictionary = {}
@export var masks: Dictionary = {}
@export var group_name: String = ""

@onready var ground_mask_bw_threshold = ProjectSettings.get_setting("shader_globals/ground_mask_bw_threshold").value

func _ready() -> void:
	await add_to_global_group(group_name)
	create_multimesh()

func create_multimesh() -> void:
	# Create a single MultiMeshInstance3D for the entire chunk
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = highest_cells.size() * instances_per_cluster  # Example: 16 instances per cluster

	# Assign a mesh to the MultiMesh
	var mesh = instance_mesh  # Replace with your desired mesh
	multimesh.mesh = mesh

	# Get the mesh's height using its AABB
	var mesh_aabb = mesh.get_aabb()
	var mesh_height = mesh_aabb.size.y  # The height of the mesh

	var current_mask
	if masks.has("GroundMask") && self.is_in_group("GRASS"):
		current_mask = masks["GroundMask"]
	var cell_pos_array :Array = []

	# Populate the MultiMesh with instances
	var i_cell = 0
	for cell_pos in highest_cells.keys():
		var allow = true
		if current_mask:
			var mask_color: Color = current_mask[i_cell]
			if mask_color != Color.BLACK:
				allow = current_mask[i_cell].r >= ground_mask_bw_threshold
			else: allow = false
		#if masks.has("GroundMask") && self.is_in_group("GRASS"):
		#	var mask_array = masks["GroundMask"]

		if allow:
			# calculate the base position of the cell		
			var x = cell_pos.x
			var z = cell_pos.y
			var y = (highest_cells[cell_pos] + 1) * cell_size.y  # Base position on top of the cell


			# Adjust the y position to account for the mesh's height
			y += mesh_height / 2  # Center the mesh on top of the cell
			cell_pos_array.append(Vector3(x, y, z))
		i_cell += 1

	# TODO: make this optional - Godrays needs it, grass doesn't (unless visibility instances is not static)
	# TODO: if we keep this in order, we can to the mask check inside
	if self.is_in_group("SUN"):
		cell_pos_array.shuffle()  # Shuffle the cell positions to randomize the distribution
	var index = 0
	for cell_pos in cell_pos_array:
		var x = cell_pos.x
		var y = cell_pos.y
		var z = cell_pos.z
		# Distribute instances within the boundaries of the cell
		for cluster_index in range(instances_per_cluster):  # Example: 16 instances per cluster
			# Calculate the position within the cell boundaries
			var offset_x = randf() * cell_size.x - (cell_size.x / 2.0)  # Random offset within the cell's x boundary
			var offset_z = randf() * cell_size.z - (cell_size.z / 2.0)  # Random offset within the cell's z boundary
			var instance_position = Vector3(
				(x * cell_size.x) + offset_x,  # Position within the x boundary
				y,                             # Position adjusted for the mesh height
				(z * cell_size.z) + offset_z   # Position within the z boundary
			)

			# Set the transform for this instance
			var trans = Transform3D()
			trans.origin = instance_position
			#var custom_data = Color(instance_position.x, instance_position.y, instance_position.z, 1.0)  # Example custom data
			#multimesh.set_instance_custom_data(index, custom_data)
			multimesh.set_instance_transform(index, trans)
			index += 1
	
	multimesh.visible_instance_count = multimesh.instance_count
	log_debug("MultiMesh created with %d instances." % multimesh.instance_count)

func add_to_global_group(group: String) -> void:
	# Add the MultiMeshInstance3D to the specified group
	add_to_group(group)
	log_debug("Added to group: %s" % group)

func set_color(color: Color) -> void:
	# Set the color of the MultiMeshInstance3D
	if not multimesh or not multimesh.mesh:
		return
	var material = multimesh.mesh.surface_get_material(0)
	if material:
		material.set_shader_parameter("emission", color)
	#log_debug("Color set to: %s" % color)

func set_material_rotation(degrees: float) -> void:
	var material = multimesh.mesh.surface_get_material(0)
	if material:
		material.set_shader_parameter("rotation_z", degrees)

func set_amount_ratio(percentage: float) -> void:
	# Set the number of visible instances in the MultiMesh
	if not multimesh:
		return
	multimesh.visible_instance_count = round(percentage * multimesh.instance_count)

func log_debug(message: String, custom_name: String = "") -> void:
	#if debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
