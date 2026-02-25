class_name FoliageParticles3D
extends GPUParticles3D

@export var draw_mesh: Mesh
@export var instance_amount: int = 0
@export var instance_lifetime: float = 10.0
@export var spawn_explosiveness: float = 0.0
@export var spawn_randomness: float = 1.0
@export_enum("GRASS", "LEAF") var foliage_category: String = "GRASS"
@export_enum("WIND", "IMPACT") var foliage_behaviour: String = "WIND"

const PROCESSMAT = {
	"GRASSWIND": preload("uid://cjwe13bal7dw2"),
	"GRASSIMPACT": preload("uid://g688xbr4t4nw"),
	"LEAFWIND": null,
	"LEAFIMPACT": null
}


func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	setParticleProperties()

func setParticleProperties() -> void:
	if draw_mesh: draw_pass_1 = draw_mesh
	amount = instance_amount
	lifetime = instance_lifetime
	randomness = spawn_randomness
	
	var behaviour_key = foliage_category+foliage_behaviour
	if PROCESSMAT.has(behaviour_key):
		process_material = PROCESSMAT[behaviour_key]
	
	if foliage_behaviour == "IMPACT":
		explosiveness = 0.95
		one_shot = true
	if foliage_behaviour == "WIND":
		explosiveness = 0.0
		one_shot = false
	emitting = true

func setProcessMaterial() -> void:
	pass


func _on_finished() -> void:
	print("finished")
	if foliage_behaviour == "IMPACT": queue_free()
