extends GPUParticles3D

func emit(state: bool) -> void:
	print(self)
	emitting = state
	set_amount_ratio(1.0)
