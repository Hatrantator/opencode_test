extends PlayerState


func enter(_msg := {}) -> void:
	#_print(self.name+"-State entered")
	player.can_move = false
	play_attack()

func play_attack() -> void:
	get_tree().call_group("FoliageManager", "deleteFoliageInstances", player.attack_area_3d.global_position, 2.0)
	player.can_move = true
	state_machine.transition_to("Idle")


func exit()-> void:
	_print(self.name+"-State exited")
