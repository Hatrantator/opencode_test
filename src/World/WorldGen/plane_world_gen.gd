extends Node3D

## Settings
@export var debug: bool = false
@export var player_character:Node3D
@export var distance:int = 2

var PARTITION = preload("res://src/World/WorldGen/plane_chunk.tscn")
#var WORLD_END = preload("res://src/world_end_block.tscn")
@onready var partitions: Node3D = $Partitions
@onready var current_cell: Vector2
@onready var global_cache = global_position

var length = ProjectSettings.get_setting("shader_globals/world_partition_length").value
var partition_array: Array = []
var partition_cells: Array = []
var partition_instance_cells: Array = []

func _ready() -> void:
	populate_plane()
	player_character.allow_process = true

func populate_plane() -> void:
	for x in range(-distance, distance+1):
		for z in range(-distance, distance+1):
			var partition = PARTITION.instantiate()
			partition.x = x
			partition.z = z
			partitions.add_child(partition)
			partition_array.append(partition)
			partition_cells.append(Vector2(x,z))
			partition_instance_cells.append(Vector2(x,z))

func _physics_process(delta):
	var cell_cache: Vector2 = current_cell
	partitions.global_position = player_character.global_position.snapped(Vector3.ONE * length) * Vector3(1,0,1)
	current_cell = Vector2(global_position.x, global_position.z) / length
	#if cell_cache != current_cell: update_worldmap(cell_cache.direction_to(current_cell).normalized())
