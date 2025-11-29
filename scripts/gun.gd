extends Node3D

@onready var gun_ray = $RayCast3D

var bulletScene = load("res://scenes/bullet.tscn")
var bulletObject
var is_shooting = false

func _ready() -> void:
	pass 

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
			shoot_homing_missile()


func shoot_homing_missile():
	var bullet = bulletScene.instantiate()
	get_tree().root.add_child(bullet) 

	bullet.global_position = gun_ray.global_position
	bullet.global_transform.basis = gun_ray.global_transform.basis
	
	bullet.setup_bullet(multiplayer.is_server())
