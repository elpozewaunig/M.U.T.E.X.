extends TextureRect

@export var player:CharacterBody3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pan_camera()
	
func pan_camera():
	var playerrot = player.rotation_degrees.y
	print(playerrot)
	rotation_degrees = -playerrot
