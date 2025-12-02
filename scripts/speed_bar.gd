extends TextureProgressBar
@export var playerMovementNode: Node3D
@export var player:CharacterBody3D
@export var speedColor:Color
@export var boostColor:Color
@export var gradient: Gradient

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_speed()

func update_speed():
	if not player:
		return
	value = player.velocity.length()
