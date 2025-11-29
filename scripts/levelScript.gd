extends Node3D # Or Node2D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene 
@onready var enemySpawner: MultiplayerSpawner = $EnemySpawner

func _ready():
	# If this is the Host, spawn existing players (like yourself)
	if multiplayer.is_server():
		# 1 is always the ID of the server
		add_player(1) 
		
		# Connect to the signals from NetworkManager to handle future connections
		NetworkManager.player_connected.connect(add_player)
		NetworkManager.player_disconnected.connect(remove_player)
		
		# Spawn anyone who is already connected (rare edge case but good practice)
		for id in multiplayer.get_peers():
			add_player(id)

func add_player(peer_id, _player_info = {}):
	print("Adding Player to Scene " + str(peer_id))
	# Instantiate the player
	var player = player_scene.instantiate()
	
	# IMPORTANT: Set the name to the ID. 
	# The MultiplayerSpawner tracks nodes by name.
	player.name = str(peer_id) 
	
	# Add to the specific node you set in your MultiplayerSpawner "Spawn Path"
	$Players.add_child(player)

func remove_player(peer_id):
	var player = $Players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		
func spawn_enemy(): 
	if not multiplayer.is_server():
		# Only host may spawn enemies
		return;
		
	var route_data = $PatrolRouteManager.get_random_route()

	var enemy_instance = enemy_scene.instantiate();
	var enemyTypes = [1,2]
	enemy_instance.initialize(enemyTypes.pick_random(), route_data["points"])

	$Enemies.add_child(enemy_instance)
	enemy_instance.set_multiplayer_authority(1)

func _on_enemy_spawn_timer_timeout() -> void:
	spawn_enemy()
