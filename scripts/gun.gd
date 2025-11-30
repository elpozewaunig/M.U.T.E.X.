extends Node3D

@onready var gun_ray = $RayCast3D
# Ensure this points to the new PHYSICS-ONLY missile (no sync node)
var missile_scene = load("res://scenes/Missile.tscn")

func _process(_delta):
	# Input Guard
	if not owner.is_multiplayer_authority():
		return
		
	if Input.is_action_just_pressed("shoot") && $Timer.is_stopped():
		$Timer.start()
		$Shoot.start()

func _on_shoot_timeout() -> void:
	request_fire()

func request_fire():
	var pos = gun_ray.global_position
	var rot = gun_ray.global_transform.basis
	
	if multiplayer.is_server():
		# Server: Broadcast directly
		rpc("fire_event", pos, rot, true)
	else:
		# I am Client: Ask Server to broadcast
		rpc_id(1, "request_fire_from_client", pos, rot, false)


@rpc("any_peer", "call_local")
func request_fire_from_client(pos, rot, is_host):
	if multiplayer.is_server():
		rpc("fire_event", pos, rot, is_host)


@rpc("any_peer", "call_local")
func fire_event(pos, rot, is_host):
	var missile = missile_scene.instantiate()
	get_node("/root/LevelScene/Bullets").add_child(missile)
	
	# Setup physics immediately
	if missile.has_method("setup_missile"):
		missile.setup_missile(pos, rot, is_host)
