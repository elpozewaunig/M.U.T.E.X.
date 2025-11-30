extends SpringArm3D

@export_group("Sensitivity")
@export var mouse_sensitivity := 0.1
@export var joystick_sensitivity := 120.0 
@export var return_speed := 10.0 

@export_group("Camera")
@export var stoppedFOV:float=75
@export var flyingFOV:float=90
@export var boostFOV:float=110
@export var camera:Camera3D

@export_group("Limits")
@export var min_pitch := -60.0 
@export var max_pitch := 40.0  
@export var max_yaw := 110.0  
 
@export_group("player")
@export var player:CharacterBody3D

@export_group("HUD")
@export var point_display: Node3D
@export var circle_hud: Node3D
@export var pitch_hud: Node3D
@export var speed_bar: Node3D

var maxSpeed:float=100
var smooth_factor: float = 15.0 
# STATE
var _current_pitch := 0.0
var _current_yaw := 0.0
var _is_using_mouse := false

# THE DEFAULT ("HOME") POSITION
var _default_pitch := 0.0
var _default_yaw := 0.0
var _default_spring_length
var shortened_spring_length = 14

func _ready():
	add_excluded_object(get_parent().get_rid())
	_default_pitch = rotation_degrees.x
	_default_yaw = rotation_degrees.y
	_default_spring_length = spring_length
	
	_current_pitch = _default_pitch
	_current_yaw = _default_yaw
	

func _input(event):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		if event is InputEventMouseMotion:
			_is_using_mouse = true
			_current_yaw -= event.relative.x * mouse_sensitivity
			_current_pitch -= event.relative.y * mouse_sensitivity
	else:
		_is_using_mouse = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta):
	var joy_input = Input.get_vector("LookLeft", "LookRight", "LookUp", "LookDown")
	var look_back = Input.is_action_pressed("LookBack")
	var is_input_active = false
	
	if joy_input.length() > 0:
		is_input_active = true
		_current_yaw -= joy_input.x * joystick_sensitivity * delta
		_current_pitch -= joy_input.y * joystick_sensitivity * delta
		
	if _is_using_mouse:
		is_input_active = true


	_current_pitch = clamp(_current_pitch, min_pitch, max_pitch)
	_current_yaw = clamp(_current_yaw, _default_yaw - max_yaw, _default_yaw + max_yaw)


	if not is_input_active:
		_current_pitch = lerp(_current_pitch, _default_pitch, return_speed * delta)
		_current_yaw = lerp(_current_yaw, _default_yaw, return_speed * delta)

	if (look_back):
		rotation_degrees.x = -5 
		rotation_degrees.y = 180
		spring_length = shortened_spring_length
		point_display.hide()
		circle_hud.hide()
		pitch_hud.hide()
		speed_bar.hide()
	else:
		rotation_degrees.x = _current_pitch
		rotation_degrees.y = _current_yaw
		spring_length = _default_spring_length
		point_display.show()
		circle_hud.show()
		pitch_hud.show()
		speed_bar.show()
	if not player or not camera:
		return
	var speed = player.velocity.length()
	if speed <= maxSpeed+1: 
		if(speed<=15):
			camera.fov= lerp(camera.fov, stoppedFOV, 2 * delta)
		else:
			camera.fov = lerp(camera.fov, flyingFOV, 2 * delta)
			
	else:
		camera.fov = lerp(camera.fov, boostFOV, smooth_factor * delta)
		
	


func _on_movement_controller_max_speed(speed: Variant) -> void:
	maxSpeed=speed
	pass # Replace with function body.
