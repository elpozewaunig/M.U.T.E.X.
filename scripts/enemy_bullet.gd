extends Area3D

@export var speed := 125.0
@export var steer_force := 50.0 
@export var damage := 1000

var velocity := Vector3.ZERO
var current_target: Node3D = null

# We need to know who shot to determine what to chase
var shooter_is_host := false 

func _ready():
	# 1. Setup Initial Velocity (Flying straight forward)
	
	
	# 2. Setup Cleanup
	$LifeTimer.timeout.connect(queue_free)
	
	# 3. Setup Collision Signals
	body_entered.connect(_on_impact)


func setup_bullet(is_fired_by_host: bool):
	shooter_is_host = is_fired_by_host
	velocity = -global_transform.basis.z * speed
	# RESET MASKS
	collision_mask = 0
	$DetectionArea.collision_mask = 0
	
	# Fires on the map both players and other enemies (but no homing on the later)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)
	set_collision_mask_value(5, true)
	$DetectionArea.set_collision_mask_value(4, true)
	$DetectionArea.set_collision_mask_value(5, true)


func _physics_process(delta):
	# 1. FIND TARGET (If we don't have one)
	if not is_instance_valid(current_target):
		find_best_target()
	
	# 2. STEER TOWARDS TARGET
	if is_instance_valid(current_target):
		var target_dir = (current_target.global_position - global_position).normalized()
		
		# Rotate the current velocity vector towards the target direction
		# We use move_toward or slerp to turn gradually (missile behavior)
		var new_dir = velocity.normalized().slerp(target_dir, steer_force * delta)
		velocity = new_dir * speed
		
		# Rotate the mesh to look where we are going
		look_at(global_position + velocity, Vector3.UP)

	# 3. MOVE
	position += velocity * delta

func find_best_target():
	# Get all bodies inside the large Detection Sphere
	var possible_targets = $DetectionArea.get_overlapping_bodies()
	
	if possible_targets.is_empty():
		return
		
	# Find the closest one
	var closest_dist = INF
	var best_candidate = null
	
	for body in possible_targets:
		# Since we set the DetectionArea Mask in 'setup_bullet', 
		# we are GUARANTEED that 'body' is the correct enemy type.
		var dist = global_position.distance_to(body.global_position)
		if dist < closest_dist:
			closest_dist = dist
			best_candidate = body
			
	current_target = best_candidate

func _on_impact(body):
	print("Bullet hit: ", body.name)
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# TODO: Spawn explosion effect here if you have one
	queue_free()
