extends CharacterBody3D

var health = 100
var typeId: int; # 1 -> Host, 2 -> Client 

@export_group("Movement Settings")
@export var MOVEMENT_SPEED = 15.0
@export var ROTATION_SPEED = 3.0
@export var WAYPOINT_REACH_DISTANCE = 5.0

@export_group("Combat Settings")
@export var ATTACK_RANGE = 40.0
@export var AVOID_RANGE = 5.0
@export var DETECTION_RANGE = 50.0

@export_group("Obstacle Avoidance")
@export var OBSTACLE_DETECT_DISTANCE = 25.0
@export var AVOIDANCE_FORCE = 2.0
@export var RAYCAST_COUNT = 5 
@export var ASTEROID_COLLISION_LAYER = 1

@export_group("Path Settings")
@export var PATROL_PATH_GROUP_NAME = "PatrolPaths"
@export var PLAYERS_GROUP_NAME = "Players"

# State Machine
enum { PATROLLING, CHASING, ATTACKING }
var current_state = PATROLLING

# Patrol System
var patrol_points: Array[Vector3] = []
var current_patrol_index = 0

# Target Tracking
var target_player: CharacterBody3D = null

func _ready() -> void:
	if not is_multiplayer_authority():
		return
	
func initialize(enemy_type_id: int, path_points: Array[Vector3]) -> void:
	typeId = enemy_type_id
	
	match enemy_type_id:
		1:
			# Layer 2, Mask: 1, 4, 5
			set_collision_layer_value(2, true)
			set_collision_mask_value(1, true)
			set_collision_mask_value(4, true)
			set_collision_mask_value(5, true)
		2:
			# Layer 3, Mask: 1, 4, 5
			set_collision_layer_value(3, true)
			set_collision_mask_value(1, true)
			set_collision_mask_value(4, true)
			set_collision_mask_value(5, true)
		_:
			push_error("Unknown enemy type: %d" % enemy_type_id)
	
	patrol_points = path_points
	
	var random_index = randi() % path_points.size()
	var spawn_position: Vector3 = patrol_points[random_index];
	call_deferred("set_global_position", spawn_position)

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
	var desired_direction = (target_point - global_position).normalized()
	
	# detect obstacles
	var avoidance_direction = detect_obstacles(desired_direction)
	var final_direction = (desired_direction + avoidance_direction).normalized()
	
	move_in_direction(final_direction, delta)
	
	if global_position.distance_to(target_point) < WAYPOINT_REACH_DISTANCE:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		# print("Reached waypoint %d, moving to next" % current_patrol_index)

func chase_player(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		current_state = PATROLLING
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	var desired_direction = (target_player.global_position - global_position).normalized()
	

	var avoidance_direction = detect_obstacles(desired_direction)
	var final_direction = (desired_direction + avoidance_direction).normalized()
	
	if distance > ATTACK_RANGE:
		move_in_direction(final_direction, delta)
	elif distance < AVOID_RANGE:
		move_in_direction(-final_direction, delta)
	else:
		velocity = Vector3.ZERO
		rotate_towards(desired_direction, delta)
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
		# TODO: Implement shooting/attacking
	elif distance < AVOID_RANGE:
		var avoidance = detect_obstacles(-direction)
		move_in_direction((-direction + avoidance).normalized(), delta)
	else:
		current_state = CHASING


func detect_obstacles(desired_direction: Vector3) -> Vector3:
	var avoidance_vector = Vector3.ZERO
	
	var front_clear = check_asteroid_ray(global_position, desired_direction, OBSTACLE_DETECT_DISTANCE)
	
	if not front_clear:
		# Hindernisse in Hauptrichtung - suche freien Weg
		var best_direction = Vector3.ZERO
		var best_score = -1.0
		
		# Shoot RAYCAST_COUNT amount of ray casts to check multiple directions around the obstacle
		for i in range(RAYCAST_COUNT):
			var angle = (i - RAYCAST_COUNT / 2.0) * 30.0  # ±60° Spread
			var test_direction = desired_direction.rotated(Vector3.UP, deg_to_rad(angle))
			
			# Check vertical avoidance manevour
			var vertical_angle = (i % 2) * 30.0 - 15.0
			test_direction = test_direction.rotated(test_direction.cross(Vector3.UP).normalized(), deg_to_rad(vertical_angle))
			
			if check_asteroid_ray(global_position, test_direction, OBSTACLE_DETECT_DISTANCE):
				# found unobstructed way
				var score = test_direction.dot(desired_direction)
				if score > best_score:
					best_score = score
					best_direction = test_direction
		
		if best_direction != Vector3.ZERO:
			avoidance_vector = (best_direction - desired_direction) * AVOIDANCE_FORCE
	
	return avoidance_vector

func check_asteroid_ray(from: Vector3, direction: Vector3, distance: float) -> bool:
	# Shoots RayCast to check if something is in the way
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		from,
		from + direction.normalized() * distance
	)
	query.exclude = [self]
	query.collision_mask = ASTEROID_COLLISION_LAYER
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()
	
func check_player_ray(from: Vector3, direction: Vector3, distance: float) -> bool:
	var space_state = get_world_3d().direct_space_state
	return true #TODO implement

func move_in_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() > 0.001:
		rotate_towards(direction, delta)
		velocity = direction * MOVEMENT_SPEED
	else:
		velocity = Vector3.ZERO
	
	move_and_slide()

func rotate_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	
	var target_basis = Basis.looking_at(direction, Vector3.UP)
	basis = basis.slerp(target_basis, ROTATION_SPEED * delta)

func _on_detection_area_body_entered(body: Node3D) -> void:
	# print("Something entered detection: ", body.name, " Groups: ", body.get_groups())
	if current_state == PATROLLING and body.is_in_group(PLAYERS_GROUP_NAME):
		target_player = body
		current_state = CHASING
		print("Player detected! Switching to chase mode")

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == target_player:
		target_player = null
		current_state = PATROLLING
		print("Player lost! Returning to patrol")
		

#Chris injected low quality code here
func take_damage(damage):
	health = health - damage
	if health <= 0:
		queue_free()
