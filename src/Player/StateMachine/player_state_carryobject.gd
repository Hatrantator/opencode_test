extends PlayerState


func enter(_msg := {}) -> void:
	#_print(self.name+"-State entered")
	get_object()
	player.can_move = false

func get_object() -> void:
	var nearest: int = 0
	for i in player.pickable_objects.size():
		var distance = player.global_position.distance_squared_to(player.pickable_objects[i].global_position)
		if distance < player.global_position.distance_squared_to(player.pickable_objects[nearest].global_position):
			nearest = i
	await player.grab_object(player.pickable_objects[nearest])
	player.can_move = true

func physics_update(delta: float) -> void:
	if player.grabbed_object and player.can_move:
		player.grabbed_object.global_position = player.carry_object_pivot.global_position

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("grab") and player.grabbed_object:
		player.grab_object(player.grabbed_object)
		state_machine.transition_to("Idle")


func exit()-> void:
	_print(self.name+"-State exited")
