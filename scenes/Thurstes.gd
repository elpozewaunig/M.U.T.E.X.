extends Node3D


@export var player :CharacterBody3D
@export var thrusterMain:Node3D
@export var thrusterLeft:Node3D
@export var thrusterRight:Node3D
@export var movement: Node3D
var maxSpeed:float = 100
@export var min_scale_z: float = 0.2 # Normale Länge (bei Stillstand)
@export var max_scale_z: float = 0.5 # Maximale Länge (bei 70 km/h)
@export var max_normalSpeed:float =0.5
@export var max_boosterSpeed:float=0.7
@export var smooth_factor: float = 10.0 # Wie weich die Änderung passiert (höher = schneller)



func _physics_process(delta: float) -> void:
	if not player or not thrusterMain:
		return
	
	var velocity=player.velocity.length();
	
	if(velocity> maxSpeed):
		max_scale_z=max_boosterSpeed
	else:
		max_scale_z=max_normalSpeed
	var target_z = remap(velocity, 0.0, maxSpeed,min_scale_z,max_scale_z)
	
	target_z = clamp(target_z, min_scale_z, max_scale_z)
	
	thrusterMain.scale.y = lerp(thrusterMain.scale.y, target_z, smooth_factor * delta)
	thrusterLeft.scale.y = lerp(thrusterLeft.scale.y, target_z, smooth_factor * delta)
	thrusterRight.scale.y = lerp(thrusterRight.scale.y, target_z, smooth_factor * delta)


func _on_movement_controller_max_speed(speed: Variant) -> void:
	maxSpeed=speed
