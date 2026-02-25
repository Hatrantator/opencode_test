extends PlayerState

var speed_cache

func enter(_msg := {}) -> void:
	#_print(self.name+"-State entered")
	speed_cache = player.move_speed
	player.move_speed += 2

func handle_input(event: InputEvent) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#if event.is_action_pressed("jump") and player.is_on_floor():
		#_print("Idle transitions to Air")
		#state_machine.transition_to("Air", {jump = true})
	#if event.is_action_pressed("shoot"):
		#_print("Idle transitions to Combat")
		#state_machine.transition_to("Combat", {attack = true})
	#if event.is_action_pressed("dodge") and player.is_on_floor() and input_strength > 0:
		#_print("Idle transitions to Combat")
		#state_machine.transition_to("Combat", {dodge = true})
	#if event.is_action_pressed("skill"):
		#_print("Idle transitions to Skill")
		#state_machine.transition_to("Skill")
	if event.is_action_released("sprint"):
		state_machine.transition_to("Walk")
	if input_dir == Vector2.ZERO:
		state_machine.transition_to("Idle")


func exit()-> void:
	player.move_speed = speed_cache
	_print(self.name+"-State exited")
