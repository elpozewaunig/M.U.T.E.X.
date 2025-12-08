extends Node3D
@export var visuals_node: Node3D
@export var guns_node: Node3D

func apply_visibility(type_id: int):
	if (not multiplayer):
		return
	
	var is_host = multiplayer.is_server()

	# Logic:
	# Type 1: Visible to Host (Server), Invisible to Client
	# Type 2: Invisible to Host, Visible to Client
	print("apply Visibility")
	print(str(type_id))
	if type_id == 1:
		visuals_node.visible = not is_host
		guns_node.visible = not is_host
	elif type_id == 2:
		visuals_node.visible = is_host
		guns_node.visible = is_host
