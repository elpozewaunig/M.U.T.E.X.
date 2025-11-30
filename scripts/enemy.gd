extends CharacterBody3D

var health = 100
var typeId: int; # 1 -> Seen by Host/Shot by Client, 2 -> Seen by Client/Shot by Host

@onready var player_shape_cast: ShapeCast3D = $PlayerShapeCast
@onready var guns: Node3D = $Guns
@onready var gun_cooldown_timer = $GunCooldown

@export var model_container: Node3D

@export_group("Movement Settings")
@export var MOVEMENT_SPEED = 60.0
@export var ROTATION_SPEED = 1.5
@export var WAYPOINT_REACH_DISTANCE = 20.0

@export_group("Visual Banking")
@export var max_bank_angle := 70.0
@export var bank_smoothness := 5.0 
@export var max_pitch_angle := 75.0 

@export_group("Combat Settings")
@export var ATTACK_RANGE = 50.0
@export var AVOID_RANGE = 20.0

@export_group("Obstacle Avoidance")
@export var OBSTACLE_DETECT_DISTANCE = 70.0 # How far ahead are obstacles detected
@export var AVOIDANCE_FORCE = 3.0 # how strong should the avoidance movement be
@export var RAYCAST_COUNT = 36 # how many directions are tested for collision avoidance
@export var ASTEROID_COLLISION_LAYER = 1
@export var BODY_WIDTH = 15.0
@export var BODY_HEIGHT = 1.5 

@export_group("Path Settings")
@export var PATROL_PATH_GROUP_NAME = "PatrolPaths"
@export var PLAYERS_GROUP_NAME = "Players"
@export var type1:Color
@export var type2:Color
@export var ship:Node3D

# State Machine
enum { PATROLLING, CHASING, ATTACKING }
var current_state = PATROLLING

# Patrol System
var patrol_points: Array[Vector3] = []
var current_patrol_index = 0

# Target Tracking
var target_player: CharacterBody3D = null

var smooth_avoidance: Vector3 = Vector3.ZERO
var smooth_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Only the Server runs the AI Logic loop.
	# Clients just exist to show the mesh and have collisions.
	if not is_multiplayer_authority():
		return
		
	gun_cooldown_timer.start()

# Called by the Spawner (Level Script) on the SERVER only
func initialize(enemy_type_id: int, path_points: Array[Vector3]) -> void:
	# 1. SETUP PATHING (Server Only)
	patrol_points = path_points
	if not patrol_points.is_empty():
		var random_index = randi() % path_points.size()
		global_position = patrol_points[random_index]
	
	# 2. SETUP TYPE (Networked)
	# We use an RPC so the Client gets the message to set up Layers & Visuals
	rpc("setup_enemy_type", enemy_type_id)

# This function runs on Server AND Clients
@rpc("call_local", "reliable")
func setup_enemy_type(id: int):
	typeId = id
	
	# Reset Layers
	collision_layer = 0
	collision_mask = 0
	
	match id:
		1:
			# Layer 2 | Mask: 1 (Map), 4 (Host), 5 (Client)
			set_collision_layer_value(2, true)
			set_collision_mask_value(1, true)
			set_collision_mask_value(4, true)
			set_collision_mask_value(5, true)
			ship.get_child(0).mesh.surface_get_material(1).albedo_color=type1
			
		2:
			# Layer 3 | Mask: 1, 4, 5
			set_collision_layer_value(3, true)
			set_collision_mask_value(1, true)
			set_collision_mask_value(4, true)
			set_collision_mask_value(5, true)
			ship.get_child(0).mesh.surface_get_material(1).albedo_color=type2
		_:
			push_error("Unknown enemy type: %d" % id)
			
	# Apply Visibility (Handling potential typo in node name)
	if has_node("VisibilityController"):
		$VisibilityController.apply_visibility(typeId)
	elif has_node("VisibilityConstroller"):
		$VisibilityConstroller.apply_visibility(typeId)

func _setup_patrol_path() -> void:
	var all_paths: Array = get_tree().get_nodes_in_group(PATROL_PATH_GROUP_NAME)
	if all_paths.is_empty():
		push_error("No Path3D nodes with group '%s' found" % PATROL_PATH_GROUP_NAME)
		return
	
	# Take random path
	var selected_path: Path3D = all_paths.pick_random()
	_load_patrol_points(selected_path)
	
	# print("Enemy spawned with %d patrol points" % patrol_points.size())

func _load_patrol_points(path: Path3D) -> void:
	patrol_points.clear()
	var curve: Curve3D = path.curve
	for i in range(curve.point_count):
		var local_point = curve.get_point_position(i)
		var global_point = path.to_global(local_point)
		patrol_points.append(global_point)

func _physics_process(delta: float) -> void:
	# Only Server calculates movement
	if not is_multiplayer_authority():
		return
	
	match current_state:
		PATROLLING:
			patrol(delta)
		CHASING:
			chase_player(delta)
		ATTACKING:
			attack_player(delta)

func patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return
	
	var target_point = patrol_points[current_patrol_index]
	
	if global_position.distance_to(target_point) < WAYPOINT_REACH_DISTANCE:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		target_point = patrol_points[current_patrol_index]
	
	var desired_direction = (target_point - global_position).normalized()
	
	# detect obstacles
	var avoidance_direction = detect_obstacles(desired_direction)
	var final_direction = (desired_direction + avoidance_direction).normalized()
	
	move_in_direction(final_direction, delta)
	
	
func chase_player(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		current_state = PATROLLING
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	var desired_direction = (target_player.global_position - global_position).normalized()
	
	var avoidance_direction = detect_obstacles(desired_direction)
	var final_direction = (desired_direction + avoidance_direction).normalized()
	
	if distance > ATTACK_RANGE:
		shoot_gun()
		move_in_direction(final_direction, delta)
	elif distance < AVOID_RANGE:
		move_in_direction(-final_direction, delta)
	else:
		velocity = Vector3.ZERO
		rotate_towards(desired_direction, delta)
		shoot_gun()
		current_state = ATTACKING

func attack_player(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		current_state = PATROLLING
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	var direction = (target_player.global_position - global_position).normalized()
	
	rotate_towards(direction, delta)
	
	if distance < ATTACK_RANGE and distance > AVOID_RANGE:
		velocity = Vector3.ZERO
		shoot_gun()
	elif distance < AVOID_RANGE:
		var avoidance = detect_obstacles(-direction)
		move_in_direction((-direction + avoidance).normalized(), delta)
	else:
		current_state = CHASING

func detect_obstacles(desired_direction: Vector3) -> Vector3:
	var avoidance_vector = Vector3.ZERO
	
	# Check front
	var asteroid_clear = check_asteroid_ray(global_position, desired_direction, OBSTACLE_DETECT_DISTANCE)
	var enemy_clear = check_enemy_ray(global_position, desired_direction, OBSTACLE_DETECT_DISTANCE * 0.6)
	
	var front_clear = asteroid_clear and enemy_clear
	
	if not front_clear:
		var best_direction = Vector3.ZERO
		var best_score = -1.0
		
		# Test directions in a sphere around the desired direction
		for i in range(RAYCAST_COUNT):
			# Horizontal angle: spread evenly around 360°
			var h_angle = (i / float(RAYCAST_COUNT)) * 360.0
			var test_direction = desired_direction.rotated(Vector3.UP, deg_to_rad(h_angle))
			
			# Vertical layers: -60°, -30°, 0°, +30°, +60°
			var v_layer = i % 5
			var v_angle = (v_layer - 2) * 30.0  # -60, -30, 0, 30, 60
			
			var side_axis = test_direction.cross(Vector3.UP).normalized()
			if side_axis.length_squared() > 0.001:
				test_direction = test_direction.rotated(side_axis, deg_to_rad(v_angle))
			
			# Check if this direction is clear
			var test_asteroid_clear = check_asteroid_ray(global_position, test_direction, OBSTACLE_DETECT_DISTANCE)
			var test_enemy_clear = check_enemy_ray(global_position, test_direction, OBSTACLE_DETECT_DISTANCE * 0.6)
			
			if test_asteroid_clear and test_enemy_clear:
				# Score: prefer directions close to desired direction
				var score = test_direction.dot(desired_direction)
				if score > best_score:
					best_score = score
					best_direction = test_direction
		
		if best_direction != Vector3.ZERO:
			avoidance_vector = (best_direction - desired_direction) * AVOIDANCE_FORCE
	
	smooth_avoidance = smooth_avoidance.lerp(avoidance_vector, 0.15)
	return smooth_avoidance


func check_asteroid_ray(from: Vector3, direction: Vector3, distance: float) -> bool:
	var space_state = get_world_3d().direct_space_state
	
	var right = global_transform.basis.x.normalized()
	var up = global_transform.basis.y.normalized()
	var wing_offset = BODY_WIDTH / 2.0
	var height_offset = BODY_HEIGHT / 2.0
	
	# 9 Test-Points: Center + 8 Edges/Nodes
	var test_points = [
		from,                                              # Center
		from + right * wing_offset,                        # Rechts
		from - right * wing_offset,                        # Links
		from + up * height_offset,                         # Oben
		from - up * height_offset,                         # Unten
		from + right * wing_offset + up * height_offset,   # Rechts-Oben
		from + right * wing_offset - up * height_offset,   # Rechts-Unten
		from - right * wing_offset + up * height_offset,   # Links-Oben
		from - right * wing_offset - up * height_offset    # Links-Unten
	]
	
	for test_from in test_points:
		var test_to = test_from + direction.normalized() * distance
		var query = PhysicsRayQueryParameters3D.create(test_from, test_to)
		query.exclude = [self]
		query.collision_mask = ASTEROID_COLLISION_LAYER
		
		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			return false
	
	return true

func check_enemy_ray(from: Vector3, direction: Vector3, distance: float) -> bool:
	"""
	Checks with five rays if enemys are in the way
	"""
	var space_state = get_world_3d().direct_space_state
	
	# Center Ray
	if not _single_ray_check(space_state, from, direction, distance, (1 << 1) | (1 << 2)):
		return false
	
	# Offset Rays
	var right = global_transform.basis.x.normalized()
	var up = global_transform.basis.y.normalized()
	
	var wing_offset = BODY_WIDTH / 2.0
	var height_offset = BODY_HEIGHT / 2.0
	
	var offsets = [
		from + right * wing_offset,
		from - right * wing_offset,
		from + up * height_offset,
		from - up * height_offset
	]
	
	for offset_pos in offsets:
		if not _single_ray_check(space_state, offset_pos, direction, distance, (1 << 1) | (1 << 2)):
			return false
	
	return true

func _single_ray_check(space_state: PhysicsDirectSpaceState3D, from: Vector3, direction: Vector3, distance: float, mask: int) -> bool:
	var query = PhysicsRayQueryParameters3D.create(
		from,
		from + direction.normalized() * distance
	)
	query.exclude = [self]
	query.collision_mask = mask
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func move_in_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() > 0.001:
		rotate_towards(direction, delta)
		
		# Smooth velocity changes
		var target_velocity = direction * MOVEMENT_SPEED
		smooth_velocity = smooth_velocity.lerp(target_velocity, 8.0 * delta)
		velocity = smooth_velocity
	else:
		smooth_velocity = smooth_velocity.lerp(Vector3.ZERO, 8.0 * delta)
		velocity = smooth_velocity
	move_and_slide()

func rotate_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		if model_container:
			model_container.rotation.z = lerp(model_container.rotation.z, 0.0, delta * bank_smoothness)
			model_container.rotation.x = lerp(model_container.rotation.x, 0.0, delta * bank_smoothness)
		return
	
	var normalized_direction = direction.normalized()
	
	var local_target_dir = global_transform.basis.inverse() * normalized_direction
	var target_bank = -local_target_dir.x * max_bank_angle
	var target_pitch = local_target_dir.y * max_pitch_angle 
	
	target_bank = clampf(target_bank, -max_bank_angle, max_bank_angle)
	target_pitch = clampf(target_pitch, -max_pitch_angle, max_pitch_angle)
	
	if model_container:
		model_container.rotation.z = lerp(model_container.rotation.z, deg_to_rad(target_bank), delta * bank_smoothness)
		model_container.rotation.x = lerp(model_container.rotation.x, deg_to_rad(target_pitch), delta * bank_smoothness)
	
	var target_forward = -normalized_direction
	
	var world_up = Vector3.UP
	# Anti-Gimbal-Lock Check
	if abs(target_forward.dot(world_up)) > 0.99:
		world_up = Vector3.BACK 

	var target_right = world_up.cross(target_forward).normalized()
	var target_up = target_forward.cross(target_right).normalized()
	
	var target_basis = Basis(target_right, target_up, target_forward).orthonormalized()
	
	basis = basis.slerp(target_basis, ROTATION_SPEED * delta).orthonormalized()
	
func is_player_in_sight() -> bool:
	player_shape_cast.force_shapecast_update()
	return player_shape_cast.is_colliding()

func _on_detection_area_body_entered(body: Node3D) -> void:
	#print("Something entered detection: ", body.name, " Groups: ", body.get_groups())
	if current_state == PATROLLING and body.is_in_group(PLAYERS_GROUP_NAME):
		target_player = body
		current_state = CHASING
		print("Player detected! Switching to chase mode")

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == target_player and not is_player_in_sight():
		target_player = null
		current_state = PATROLLING
		print("Player lost! Returning to patrol")
		

func shoot_gun() -> void:
	if has_node("Guns") and is_player_in_sight():
		
		if not gun_cooldown_timer.is_stopped():
			# cooldown timer has not expired yet
			return
		
		var allGuns: Array[Node] = guns.get_children()
		
		var selected_gun: Node = allGuns.pick_random()
		
		if selected_gun.has_method("shoot_homing_missile"):
			selected_gun.shoot_homing_missile(self)
			gun_cooldown_timer.start()


@rpc("any_peer", "call_local")
func take_damage(damage_amount):
	if not multiplayer.is_server():
		rpc_id(1, "take_damage", damage_amount)
		return

	health -= damage_amount
	
	if health <= 0:
		ScoreManager.add_score(1)
		print("Taking Damage")
		$Explosion.explode()
		await get_tree().create_timer(4.0).timeout
		queue_free()


func _on_collision_entered(body: Node3D) -> void:
	print("Collided with obstacle %s" % body.name)
	health = 0
	queue_free()
