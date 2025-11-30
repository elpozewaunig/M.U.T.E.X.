# Player.gd
extends CharacterBody3D

@export var movement_controller: Node3D
@export var camera_controller: Node3D
@export var camera: Camera3D

@export_group("Hud elements")
@export var point_display: Node3D
@export var circle_hud: Node3D
@export var pitch_hud: Node3D
@export var speed_bar: Node3D

signal takeDamageSignal(damageAmount)

func _enter_tree():
	# 1. Set Authority based on Name (Standard stuff)
	set_multiplayer_authority(str(name).to_int())

func _ready():
	collision_layer = 0
	var my_peer_id = str(name).to_int()
	
	if my_peer_id == 1:
		set_collision_layer_value(4, true)
	else:
		set_collision_layer_value(5, true)
		global_position = Vector3(15, 0, 0)
		
		
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
		
		point_display.hide()
		circle_hud.hide()
		pitch_hud.hide()
		speed_bar.hide()

func take_damage(damage_amount):
	takeDamageSignal.emit(damage_amount)
