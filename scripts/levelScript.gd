extends Node3D # Or Node2D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene 
@export var max_enemy_count: int = 70
@export var main_menu_scene: PackedScene
@onready var enemySpawner: MultiplayerSpawner = $EnemySpawner


func _ready():
	ScoreManager.game_over.connect(on_game_over)
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
		
	if $Enemies.get_child_count() >= max_enemy_count:
		return;
		
	print("Spawn enemy number %s of max. %s" % [$Enemies.get_child_count(), max_enemy_count])
		
	var route_data = $PatrolRouteManager.get_random_route()
	var enemy_instance = enemy_scene.instantiate();
	enemy_instance.name = "Enemy_%d%d" % [Time.get_ticks_usec(), randi()]
	$Enemies.add_child(enemy_instance)
	enemy_instance.set_multiplayer_authority(1)
	
	
	enemy_instance.initialize(1, route_data["points"])
func _on_enemy_spawn_timer_timeout() -> void:
	spawn_enemy()

func on_game_over():
	#TODO: maybe not the best decision will see later if animationPlayer gets fucked
	process_mode = Node.PROCESS_MODE_DISABLED
	
	if not multiplayer.is_server():
		return
	
	ScoreManager.save_current_run()
	# Tell everyone to show "Game Over" screen
	rpc("display_game_over_ui")
	
	# -> Wait 
	await get_tree().create_timer(5.0).timeout
	rpc("return_to_main_menu")

@rpc("call_local", "reliable")
func display_game_over_ui():
	#TODO: Explosion
	print("GAME OVER")

@rpc("call_local", "reliable")
func return_to_main_menu():
	get_tree().change_scene_to_packed(main_menu_scene)
	NetworkManager.cleanup_network()
	call_deferred("queue_free")
	
