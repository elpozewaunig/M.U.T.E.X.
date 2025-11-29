extends Node3D

@onready var gun_ray = $RayCast3D

# Ensure this matches your file path EXACTLY
var missile_scene = load("res://scenes/Missile.tscn")

func _process(_delta):
	# Input Guard: Only the local player can request a shot
	if not owner.is_multiplayer_authority():
		return
		
	if Input.is_action_just_pressed("shoot"):
		# Networking Check
		if multiplayer.is_server():
			spawn_missile()
		else:
			rpc_id(1, "spawn_missile")

@rpc("any_peer", "call_local")
func spawn_missile():
	# Security: Only Server spawns
	if not multiplayer.is_server(): return

	# 1. Instantiate
	var missile = missile_scene.instantiate()
	
	# 2. Force Unique Name (PREVENTS "Node Not Found" ERRORS)
	missile.name = "M_%d" % randi()
	
	# 3. Find Container
	var container = get_node("/root/LevelScene/Bullets")
	if not container:
		printerr("Gun Error: No 'Bullets' node found in LevelScene")
		return

	# 4. Add Child (Networked)
	container.add_child(missile, true)
	
	# 5. Position & Rotation
	missile.global_position = gun_ray.global_position
	missile.global_transform.basis = gun_ray.global_transform.basis
	
	# 6. Setup Logic
	# owner.name == "1" checks if the shooter is the Host
	if missile.has_method("setup_server_logic"):
		missile.setup_server_logic(owner.name == "1", owner)
