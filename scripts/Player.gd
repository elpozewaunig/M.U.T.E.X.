extends CharacterBody3D

const SPEED = 10.0

@onready var camera = $Camera3D

func _enter_tree():
	# 1. AUTHORITY SETUP
	# This ensures Player 1 controls "Player 1", and Player 2 controls "Player 2"
	set_multiplayer_authority(str(name).to_int())

func _ready():
	# DEBUG PRINT
	# Shows: [My Peer ID] Player Name: X | Authority: Y
	var my_id = multiplayer.get_unique_id()
	var owner_id = get_multiplayer_authority()
	print("[%s] Spawned Player: %s | Authority is: %s" % [my_id, name, owner_id])

	# 2. CAMERA SETUP
	if is_multiplayer_authority():
		camera.current = true
	else:
		camera.current = false

func _physics_process(delta):
	# 3. INPUT SECURITY
	# If this character does not belong to me, stop running code here.
	# The MultiplayerSynchronizer will handle moving the other players.
	if not is_multiplayer_authority():
		return

	# 4. ZERO-G MOVEMENT
	# Horizontal (X / Z)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Vertical (Y) - Using Space for Up, Shift for Down
	var vertical_dir = 0.0
	if Input.is_action_pressed("ui_accept"): # Default Spacebar
		vertical_dir = 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		vertical_dir = -1.0

	# Apply Velocity directly
	velocity.x = input_dir.x * SPEED
	velocity.z = input_dir.y * SPEED
	velocity.y = vertical_dir * SPEED
	
	if (velocity != Vector3.ZERO):
		var my_id = multiplayer.get_unique_id()
		print("[%s] Moving Player: %s" % [my_id, name])

	move_and_slide()
