extends Node3D

@onready var ray = $RayCast3D
@onready var mesh = $MeshInstance3D
@onready var homing_area = $Area3D

var speed = 10
var steering_force = 10
var target: Node3D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ray.enabled = true
	homing_area.body_entered.connect(_on_area_3d_body_entered)
	await get_tree().create_timer(3.0).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.basis * Vector3(0,0,-speed) * delta
	homing(delta)
	enemyHit()



func enemyHit():
	if ray.is_colliding():
		var collider = ray.get_collider()
		if ray.get_collider().is_in_group("enemy"):
			print("hit")
			mesh.visible = false
			ray.enabled = false
			queue_free()

func homing(delta):
	if target == null:
		return
	look_at(target.global_position, Vector3(1,1,1))
	position = position.move_toward(target.global_position, speed * delta)
	if ray.get_collider().is_in_group("enemy"):
		pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		if target != null:
			return
		if body == null:
			return
		target = body
