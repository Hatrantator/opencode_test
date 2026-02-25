class_name NPCState
extends State


# Reference to npc node
#var npc: NPC

func _ready() -> void:
	# States are children of NPC so their _ready callback will execute first.
	# Needs to wait for the owner to be ready first
	await owner.ready
	# Casts owner var tp the NPC type
	#npc = owner as NPC
	# For troubleshooting. Checks if a derived state script is assigned.
	#assert(npc != null)
	
#func _physics_process(delta):
#	if npc.weapon_ctrl.equipped_weapon:
#		npc.can_attack = true
#	else:
#		npc.can_attack = false
