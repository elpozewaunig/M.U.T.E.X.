extends Node3D

var health = 1

func take_damage(damage_amount):
	if not multiplayer.is_server():
		return

	health -= damage_amount
	
	if health <= 0:
		die()

func _on_character_body_3d_2_take_damage_signal(damageAmount: Variant) -> void:
	take_damage(damageAmount)

func _on_area_3d_body_entered(body: Node3D) -> void:
	_on_body_entered(body)

func _on_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
		
	if body.collision_layer & (1 << 0): 
		rpc_id(1, "server_handle_crash")
	
	if body.collision_layer & (1 << 3) || body.collision_layer & (1 << 4): # Layer 4 / 5 -> other player
		rpc_id(1, "server_handle_crash")


@rpc("any_peer", "call_local")
func server_handle_crash():
	if not multiplayer or not multiplayer.is_server():
		return
	
	take_damage(9999)

func die():
	ScoreManager.signal_game_over()

@rpc("call_local")
func client_die_effect():
	# Spawn particles, play sound, etc.
	print("Player " + name + " exploded!")
	$"../ExplosionSound".play()
