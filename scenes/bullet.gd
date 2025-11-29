extends Node3D

@onready var ray = $RayCast3D
@onready var mesh = $MeshInstance3D
@onready var homing_area = $Area3D

var speed = 5
var steering_force = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ray.enabled = true
	await get_tree().create_timer(3.0).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.basis * Vector3(0,0,-speed) * delta
	enemyHit()



func enemyHit():
	if ray.is_colliding():
		var collider = ray.get_collider()
		if ray.get_collider().is_in_group("enemy"):
			print("hit")
			mesh.visible = false
			ray.enabled = false
			queue_free()

func homing():
	if ray.get_collider().is_in_group("enemy"):
		pass
