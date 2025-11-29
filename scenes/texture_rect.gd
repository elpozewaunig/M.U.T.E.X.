extends TextureRect

var return_speed = 10
var pan_speed = 200
var texture_height = size.y
var texture_height_half = size.y / 2
var min_panning = -texture_height + 500
var max_panning = 200
@export var player:CharacterBody3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var viewport_height = get_viewport_rect().size.y
	var center_y_pos = (viewport_height / 2.0) - (texture_height / 2.0)
	position.y = center_y_pos+200
	# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pan_camera(delta)
	
func pan_camera(delta):
	var is_input_active = false
	#if Input.is_action_pressed("TiltDown"):
		#position.y -= pan_speed * delta
		#is_input_active = true
	#if Input.is_action_pressed("TiltUp"):
		#position.y += pan_speed * delta
		#is_input_active = true
	var playerrot=player.rotation_degrees
	
	var rot = remap(playerrot.x,-60,60,min_panning,max_panning)
	
	position.y = clamp(rot, min_panning, max_panning)
	
	if not is_input_active:
		position.y = lerp(position.y, -texture_height_half, return_speed * delta)
