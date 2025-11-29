extends Node3D

@onready var gun_ray = $RayCast3D

var bulletScene = load("res://scenes/bullet.tscn")
var bulletObject
var is_shooting = false

func _ready() -> void:
	pass 

func _process(_delta: float) -> void:
	if not owner.is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("shoot"):
		request_shoot()

func request_shoot():
	if not multiplayer.is_server():
		rpc_id(1, "server_shoot_bullet")
	else:
		server_shoot_bullet()

@rpc("any_peer", "call_local")
func server_shoot_bullet():
	if not multiplayer.is_server():
		return

	var bullet = bulletScene.instantiate()
	var bullet_container = get_node("/root/LevelScene/Bullets")
	
	if not bullet_container:
		printerr("Error: Could not find 'Bullets' node!")
		return

	bullet_container.add_child(bullet, true)

	bullet.global_position = gun_ray.global_position
	bullet.global_transform.basis = gun_ray.global_transform.basis
	
	if bullet.has_method("setup_bullet"):
		bullet.setup_bullet(owner.name == "1", owner)
