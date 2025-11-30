extends Area3D

@export var speed := 125.0
@export var steer_force := 50.0 
@export var damage := 100

# SYNCED VARIABLE
# The server sets this. The Synchronizer sends it to Clients.
# Clients read this to know who to hit.
@export var shooter_is_host := false 

var velocity := Vector3.ZERO
var current_target: Node3D = null

func _ready():
	set_multiplayer_authority(1)
	# 1. Cleanup
	$LifeTimer.timeout.connect(queue_free)
	body_entered.connect(_on_impact)

	# 2. CLIENT INITIALIZATION
	# Clients need to wait for the data (shooter_is_host) to arrive from the Server.
	if not multiplayer.is_server():
		# Turn off physics/collision momentarily to prevent bugs
		set_physics_process(false)
		monitoring = false
		
		# Wait one frame for the MultiplayerSynchronizer to update variables
		await get_tree().process_frame 
		
		# Now that we have the data, setup the masks
		_apply_collision_logic()
		
		# Turn physics back on
		monitoring = true
		set_physics_process(true)
	else:
		# Server runs immediately
		_apply_collision_logic()

# Called manually by the Gun Script (Server Only)
func setup_server_logic(is_host: bool, _shooter_node: Node3D):
	shooter_is_host = is_host
	
	# We run this immediately on server
	_apply_collision_logic()

func _apply_collision_logic():
	# Calculate velocity based on rotation (Forward is -Z)
	velocity = -global_transform.basis.z * speed
	
	# Reset Masks
	collision_mask = 0
	$DetectionArea.collision_mask = 0
	
	# Always hit Map (Layer 1)
	set_collision_mask_value(1, true)
	
	if shooter_is_host:
		# HOST FIRED: Hit Enemy 2 (Layer 3) + Client (Layer 5)
		set_collision_mask_value(3, true)
		set_collision_mask_value(5, true)
		$DetectionArea.set_collision_mask_value(3, true)
	else:
		# CLIENT FIRED: Hit Enemy 1 (Layer 2) + Host (Layer 4)
		set_collision_mask_value(2, true)
		set_collision_mask_value(4, true)
		$DetectionArea.set_collision_mask_value(2, true)

func _physics_process(delta):
	# HOMING LOGIC
	if not is_instance_valid(current_target):
		_find_target()
	
	if is_instance_valid(current_target):
		var target_dir = (current_target.global_position - global_position).normalized()
		var new_dir = velocity.normalized().slerp(target_dir, steer_force * delta)
		velocity = new_dir * speed
		look_at(global_position + velocity, Vector3.UP)

	position += velocity * delta

func _find_target():
	var targets = $DetectionArea.get_overlapping_bodies()
	if targets.is_empty(): return
	
	var closest_dist = INF
	for t in targets:
		var d = global_position.distance_to(t.global_position)
		if d < closest_dist:
			closest_dist = d
			current_target = t

func _on_impact(body):
	# VISUALS (Everyone can spawn a particle here)
	# spawn_explosion()
	
	# LOGIC (Server Only)
	if multiplayer.is_server():
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
