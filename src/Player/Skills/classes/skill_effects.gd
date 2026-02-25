class_name SkillEffect
extends Resource

@export var tween_properties: Array = []

class Effect:
	var node: Node3D
	var value: Variant
	var duration: float
	var transition: int

	func _init(node: Node3D, value: Variant, duration: float, transition: int) -> void:
		self.node = node
		self.value = value
		self.duration = duration
		self.transition = transition
