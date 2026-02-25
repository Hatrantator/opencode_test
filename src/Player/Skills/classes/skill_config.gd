class_name SkillConfig
extends Resource

@export var skill_name: String
@export var skill_description: String
@export var skill_icon: Texture2D
@export var skill_cooldown: float = 0.0
@export var skill_cost: int = 0
@export var skill_effects: Array[Dictionary] = []
@export var skill_requirements: Array[String] = []
@export var skill_animation: String = ""
@export var skill_sound: AudioStream = null
@export var skill_targeting: bool = false
@export var skill_targeting_range: float = 10.0