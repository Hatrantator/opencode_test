extends PlayerState

func enter(_msg := {}) -> void:
	_print(self.name+"-State entered")

func _physics_update(delta: float) -> void:
	if player.is_on_floor():
		state_machine.transition_to("Idle")

func exit()-> void:
	_print(self.name+"-State exited")
