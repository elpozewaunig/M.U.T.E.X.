extends SpringArm3D

@export_group("Sensitivity")
@export var mouse_sensitivity := 0.1
@export var joystick_sensitivity := 120.0 
@export var return_speed := 10.0 

@export_group("Limits")
@export var min_pitch := -60.0 
@export var max_pitch := 40.0  
@export var max_yaw := 110.0   

# STATE
var _current_pitch := 0.0
var _current_yaw := 0.0
var _is_using_mouse := false

# THE DEFAULT ("HOME") POSITION
var _default_pitch := 0.0
var _default_yaw := 0.0

func _ready():
	add_excluded_object(get_parent().get_rid())
	_default_pitch = rotation_degrees.x
	_default_yaw = rotation_degrees.y
	
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

	rotation_degrees.x = _current_pitch
	rotation_degrees.y = _current_yaw
