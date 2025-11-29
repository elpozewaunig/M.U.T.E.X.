extends Node3D

@export_group("Character & Model")
@export var player : CharacterBody3D 
@export var model_container : Node3D 

@export_group("Speed & Acceleration")
@export var MAX_SPEED := 70.0       
@export var MIN_SPEED := -0.0      
@export var acceleration := 25.0    
@export var decceleration := -45.0

@export_group("Boosting")
@export var booooooooooost_acceleration := 100.0
@export var max_speed_while_boosting := 120.0
@export var boost_duration = 1.0
@export var boost_cooldown = 2.0
var default_acceleration : float 

@export_group("Turning")
@export var yaw_speed := 80.0 
@export var max_yaw_turn_multiplier := 4.0
@export var pitch_speed := 70.0
@export var max_pitch_turn_multiplier := 2.0

# Visual
@export_group("Visual Banking")
@export var max_bank_angle := 70.0
@export var bank_smoothness := 15.0 
@export var max_pitch_angle := 60.0 # if > 85 -> you fucked. 

@export_group("Control Feel")
@export var response_speed := 10.0

@export_group("Auto Leveling")
@export var horizon_return_speed := 2.0
@export var camera_level_speed := 10.0 




var current_speed := 0.0
var current_pitch_input := 0.0
var current_yaw_input := 0.0
var remaining_boost_duration := 0.0
var current_boost_cooldown := 0.0

func _ready():
	if not player:
		player = get_parent()
	if not model_container:
		model_container = player.get_node("ModelContainer")
		
	pitch_speed = deg_to_rad(pitch_speed)
	yaw_speed = deg_to_rad(yaw_speed)
	max_bank_angle = deg_to_rad(max_bank_angle)
	
	default_acceleration = -MAX_SPEED / 5.0
	print("Visual Banking Controller Initialized")

func _physics_process(delta):
	var raw_pitch = Input.get_axis("TiltDown", "TiltUp")
	var raw_turn = Input.get_axis("RollRight", "RollLeft") 
	var acceleration_direction = Input.get_axis("Accelerate", "Break")
	var is_boosting = Input.is_action_pressed("boost");
	
	# Allow for sharper Turns when flying slower
	var yaw_turn_multiplier = 1.0
	var pitch_turn_multiplier = 1.0
	if current_speed < MAX_SPEED:
		var speed_percent = clamp(current_speed / MAX_SPEED, 0.0, 1.0)
		yaw_turn_multiplier = lerp(max_yaw_turn_multiplier, 1.0, speed_percent) 
		pitch_turn_multiplier = lerp(max_pitch_turn_multiplier, 1.0, speed_percent) 
		
	var airflow_control = clamp(abs(current_speed) / 30.0, 0.3, 1.0)
	airflow_control = clamp(abs(current_speed) / 15.0, 0.1, 1.0)
	
	yaw_turn_multiplier *= airflow_control
	pitch_turn_multiplier *= airflow_control
	
	# Smooth Input
	current_pitch_input = lerp(current_pitch_input, raw_pitch, delta * response_speed)
	current_yaw_input = lerp(current_yaw_input, raw_turn, delta * response_speed)
	
	# Restrict Turning when aggresively Pitching
	var is_vertical = abs(player.transform.basis.z.y)
	var vertical_yaw_damper = clamp(1.0 - is_vertical, 0.0, 1.0)
	
	# Rotate
	player.rotate_object_local(Vector3.RIGHT, current_pitch_input * pitch_speed * pitch_turn_multiplier * delta)
	player.rotate_object_local(Vector3.UP, current_yaw_input * yaw_speed  * yaw_turn_multiplier * vertical_yaw_damper * delta)
	
	# Limit Rotation, else Beyblade 
	var rot_deg = player.rotation_degrees
	rot_deg.x = clamp(rot_deg.x, -max_pitch_angle, max_pitch_angle)
	player.rotation_degrees = rot_deg
	
	# Level Camera to Horizon to make gameplay easier
	player.rotation.z = lerp_angle(player.rotation.z, 0.0, camera_level_speed * delta)

	if raw_pitch == 0: # only if player does not pitch
		player.rotation.x = lerp_angle(player.rotation.x, 0.0, horizon_return_speed * delta)
		
	# Is notwendig, sonst geht alles in arsch
	player.transform = player.transform.orthonormalized()
	
	# Visual Banking
	var target_bank = raw_turn * max_bank_angle
	model_container.rotation.z = lerp(model_container.rotation.z, target_bank, delta * bank_smoothness)

	var apply_boost = is_boosting and remaining_boost_duration > 0
	if apply_boost:
			remaining_boost_duration -= delta
			current_speed += booooooooooost_acceleration * delta
			current_boost_cooldown += (boost_cooldown / boost_duration) * delta

	if apply_boost and current_boost_cooldown > 0:
		current_boost_cooldown -= delta
		
	if (current_boost_cooldown <= 0):
			remaining_boost_duration = boost_duration
		
	# Move
	if acceleration_direction < 0:
		current_speed += acceleration * delta
	elif acceleration_direction > 0:
		current_speed += decceleration * delta
	elif not apply_boost:
		current_speed = move_toward(current_speed, 0.0, abs(default_acceleration) * delta)
	   
	if apply_boost:
		current_speed = clamp(current_speed, MIN_SPEED, max_speed_while_boosting)
	else: 
		current_speed = clamp(current_speed, MIN_SPEED, MAX_SPEED)
		
		
	# Move relative to where we are facing (-Z is Forward)
	player.velocity = -player.transform.basis.z * current_speed
	
	player.move_and_slide()
	
	
	# Reset (debugging)
	if Input.is_action_just_pressed("RESET"):
		current_speed = 0.0
		player.position = Vector3.ZERO
		player.rotation = Vector3.ZERO
		
