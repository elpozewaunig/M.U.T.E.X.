# Player.gd
extends CharacterBody3D

@export var movement_controller: Node3D
@export var camera_controller: Node3D
@export var camera: Camera3D

func _enter_tree():
	# 1. Set Authority based on Name (Standard stuff)
	set_multiplayer_authority(str(name).to_int())

func _ready():
	# 2. DECIDE WHO IS IN CONTROL
	if is_multiplayer_authority():
		# This is MY player. 
		# Enable Camera.
		camera.current = true
		# Enable Movement Controller.
		movement_controller.set_physics_process(true)
		camera_controller.set_process(true)
	else:
		# This is SOMEONE ELSE'S player.
		# Disable Camera.
		camera.current = false
		# KILL THE CONTROLLER. 
		# We do not want to process inputs for other people's players.
		movement_controller.set_physics_process(false)
		camera_controller.set_process(true)
