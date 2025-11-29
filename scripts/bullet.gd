extends Node3D

@onready var ray = $RayCast3D
@onready var mesh = $MeshInstance3D
@onready var homing_area = $Area3D

var speed = 115
var target: Node3D = null
var damage = 50


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
 
	await get_tree().create_timer(3.0).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	homing(delta)

func homing(delta):
	position += transform.basis * Vector3(0,0,-speed) * delta

	if target == null:
		return
	var target_transform = global_transform.looking_at(target.global_position, Vector3(0,1,0))
	#position = position.move_toward(target.global_position, 0.1 * speed * delta)
	global_transform = global_transform.interpolate_with(target_transform, 30 * delta)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemies"):
		#print("homing in now")
		if target != null:
			return
		if body == null:
			return
		target = body
		
		if body.has_method("take_damage"):
			body.take_damage(damage)

 


func _on_area_3d_bulletBody_body_entered(_body: Node3D) -> void:
	queue_free()
		
		
