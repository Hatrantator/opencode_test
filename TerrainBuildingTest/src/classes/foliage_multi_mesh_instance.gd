@tool
class_name FoliageMultiMeshInstance
extends MultiMeshInstance3D

@export var biome = 0
@export var level = 0
var allowed_biomes :PackedInt32Array = []
@export var camera: Camera3D
@export var max_render_distance: float = 150.0

@export var i_count: int = 1024 ##amount of instances
@export var size: Vector2 = Vector2(2.0,2.0) ##area where instances are spawned centered at (0.0,0.0)
@export var scale_range: Vector2 = Vector2(1.0,1.1)
@export var target_mesh: MeshInstance3D
@export_tool_button("Generate Multimesh") var gen_multimesh = self.generate_instances

##interactive parameters
@export var category: String = "GRASS"
var particle_buffer: Array = [] #contains particles3d of the multimeshes
var static_buffer: Array = [] #contains rigidbody clones of the multimeshinstances

@export var body: Node3D
@export var cut_position: Vector3 = Vector3.ZERO
@export var cut_radius: float = 2.0
@export_tool_button("Cut Multimesh") var cut_multimesh = self.cut_grass_around

@export var debug_colors: PackedColorArray = [Color.GREEN, Color.YELLOW, Color.RED, Color.BLUE_VIOLET, Color.BLACK]

var max_lod: int = 1
@export var lod: int = 0
@export var divide: bool = false
@onready var rng := RandomNumberGenerator.new()
var seed: int = 0

@export var instance_positions: Array[Vector3] = []
@export var instance_transforms: Array[Transform3D] = []
var process: bool = false
var frame_cache: int = 0
var pos_cache: Vector3

var biome_cache = -1
var i_count_cache := 0
func _update_biome() -> void:
	#change_override_material()
	#print("wazzup")
	if not allowed_biomes.has(biome):
		#print("we fucked")
		visible = false
		if i_count > 0:
			i_count_cache =  i_count
			i_count = 0
	else:
		#print("we safe")
		visible = true
		if i_count == 0:
			i_count = i_count_cache
	biome_cache = biome
	#generate_instances()

func _process(delta: float) -> void:
	if biome:
		if biome != biome_cache:
			_update_biome()

#func _physics_process(delta: float) -> void:
	#if body:# and not Engine.is_editor_hint():
		#pass
		#await cut_grass_around(body.global_position)
	
#func _physics_process(delta: float) -> void:
	#if lod == 0:
		#if process:
			#frame_cache += 1
			#if frame_cache == 10:
				#frame_cache = 0
				#var player_pos = ProjectSettings.get_setting("shader_globals/we_player_position").value
				#if pos_cache == null:
					#pos_cache = player_pos
					#return
				#if process && player_pos != null && player_pos.distance_to(self.global_position) <= 30:
					#print("%s AAAARGH" % self)
					#if !player_pos.is_equal_approx(pos_cache):
						#pos_cache = player_pos
						#cut_grass_around()

func set_seed() -> void:
	if seed > -1: rng.seed = seed
	else: rng.seed = hash(get_parent_node_3d().global_position)

func applyLOD() -> void:
	if divide:
		var lod_factor :float = (1.0/(max_lod-0.5))
		multimesh.visible_instance_count = round(multimesh.instance_count * (1.0 - (lod_factor * lod)))
		#print("%s applied LOD - visible instances: %d" % [self, multimesh.visible_instance_count])
	#else:
		#lod_bias = 1.0 - ((0.99 / (max_lod-1)) * lod)

func generate_instances():
	if level > 0: return
	var mm := multimesh
	mm.instance_count = i_count
	instance_positions.clear()
	instance_transforms.clear()

	set_seed()
	#rng.randomize()

	var half_size :Vector2 = size * 0.5

	for i in i_count:
		var pos = Vector3(
			rng.randf_range(-half_size.x, half_size.x),
			0,
			rng.randf_range(-half_size.x, half_size.x)
			#rng.randf_range(0, size.x),
			#0,
			#rng.randf_range(0, size.x)
		)
		instance_positions.append(pos)
		
		var rng_scale: float = rng.randf_range(scale_range.x, scale_range.y)
		var rng_rota: float = rng.randf_range(0.0, 360.0)

		var trans = Transform3D(Basis().scaled(Vector3.ONE * rng_scale).rotated(Vector3(0,1,0), rng_rota), pos)
		instance_transforms.append(trans)
		mm.set_instance_transform(i, trans)
		mm.set_instance_color(i, debug_colors[lod])
	
	applyLOD()
	await get_tree().process_frame
	if lod == 0 && i_count > 0:
		loadParticleBuffer()
		#addWindParticle() ##move this to player
	process = true

func generate_from_transforms(transforms):
	var mm := multimesh
	instance_positions.clear()
	instance_transforms.clear()
	
	set_seed()
	
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 0
#
	##var transforms := get_flat_surface_transforms(mesh)
#
	mm.instance_count = transforms.size()

	for i in transforms.size():
		var angle := randf() * TAU
		var radius := sqrt(randf()) * 0.33

		var offset := Vector3(
			cos(angle) * radius,
			0.0,
			sin(angle) * radius
		)
		var pos = transforms[i].origin
		pos += offset
		var rng_scale: float = rng.randf_range(scale_range.x, scale_range.y)
		var rng_rota: float = rng.randf_range(0.0, 360.0)
		var trans = Transform3D(Basis().scaled(Vector3.ONE * rng_scale).rotated(Vector3(0,1,0), rng_rota), pos)
		instance_positions.append(pos)
		instance_transforms.append(trans)
		mm.set_instance_transform(i, trans)
		
	applyLOD()
	await get_tree().process_frame
	if lod == 0 && i_count > 0:
		loadParticleBuffer()
		#addWindParticle() ##move this to player
	var mat = mm.mesh.surface_get_material(0)
	mat = mat.duplicate()
	#mat.set_shader_parameter("invert_height", true)
	mm.mesh.surface_set_material(0,mat)
	
	process = true

func cut_static(_position: Vector3):
	if category != "STATIC":
		return
	
	var new_transforms: Array[Transform3D] = []
	var new_positions: Array[Vector3] = []
	
	_position -= global_position
	
	# calculate valid instances - therefore deletes the one instance we collided with
	for i in instance_positions.size():
		var inst_pos = instance_positions[i]
		var inst_transform = instance_transforms[i]
		if not _position.is_equal_approx(inst_pos):
			new_positions.append(inst_pos)
			new_transforms.append(Transform3D(inst_transform.basis, inst_pos))

	# Update instance data
	var mm := multimesh
	mm.instance_count = new_transforms.size()
	for i in new_transforms.size():
		mm.set_instance_transform(i, new_transforms[i])
		#mm.set_instance_color(i, debug_colors[lod])
	
	instance_positions = new_positions
	instance_transforms = new_transforms

func cut_grass_around(_position: Vector3 = Vector3.ZERO, radius: float = -1.0):
	if category != "GRASS" or !process:
		return
	#print("cutting multimesh around %s" % _position)
	var new_transforms: Array[Transform3D] = []
	var new_positions: Array[Vector3] = []
	
	if radius <= 0.0:
		radius = cut_radius

	_position -= global_position

	for i in instance_positions.size():
		var inst_pos = instance_positions[i]
		var inst_transform = instance_transforms[i]
		if _position.distance_squared_to(inst_pos) > radius * radius:
			new_positions.append(inst_pos)
			#new_transforms.append(Transform3D(Basis(), inst_pos))
			new_transforms.append(Transform3D(inst_transform.basis, inst_pos))

	
	# Update instance data
	var mm := multimesh
	
	# spawn particles of the cut grass
	if lod == 0 && i_count > 0:
		var impact_amount = mm.instance_count-new_transforms.size()
		addImpactParticle(_position, impact_amount)
		
	mm.instance_count = new_transforms.size()
	for i in new_transforms.size():
		mm.set_instance_transform(i, new_transforms[i])
		#mm.set_instance_color(i, debug_colors[lod])
	
	instance_positions = new_positions
	instance_transforms = new_transforms

func loadParticleBuffer() -> void:
	for i in 10:
		var foliage_particle: FoliageParticles3D = FoliageParticles3D.new()
		foliage_particle.foliage_category = category
		foliage_particle.draw_mesh = multimesh.mesh
		particle_buffer.append(foliage_particle)

func addWindParticle() -> void: ##move this to player
	print("adding wind particles")
	var wind_particle = FoliageParticles3D.new()
	wind_particle.draw_mesh = multimesh.mesh
	wind_particle.foliage_category = category
	wind_particle.foliage_behaviour = "WIND"
	wind_particle.instance_amount = 256
	wind_particle.global_position = global_position
	#wind_particle.one_shot = false
	add_child(wind_particle)
	wind_particle.set_owner(get_tree().edited_scene_root)
	#wind_particle.emitting = true

func addImpactParticle(pos: Vector3,amount: int = 0) -> void:
	if particle_buffer.is_empty():
		loadParticleBuffer()
	if amount == 0:
		return
	var impact_particle = particle_buffer[0]
	impact_particle.foliage_behaviour = "IMPACT"
	impact_particle.instance_amount = amount
	impact_particle.position = pos
	impact_particle.one_shot = true
	add_child(impact_particle)
	impact_particle.set_owner(get_tree().edited_scene_root)
	particle_buffer.pop_front()
