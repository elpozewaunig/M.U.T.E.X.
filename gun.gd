extends Node3D

@onready var gun_ray = $RayCast3D

var bullet = load("res://scenes/bullet.tscn")
var bulletObject
var is_shooting = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		#if !is_shooting:
			shoot()


func shoot() -> void:
	bulletObject = bullet.instantiate()
	get_tree().root.add_child(bulletObject)
	bulletObject.global_transform = gun_ray.global_transform
	#await get_tree().create_timer(10).timeout
	#is_shooting = false
