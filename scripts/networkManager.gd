extends Node

# NetworkManager.gd
const PORT = 8080
var DEFAULT_SERVER_IP = "192.168.1.144" # Localhost

const LEVEL_SCENE_PATH = "res://scenes/LevelScene.tscn" 
const CLIENT_CONNECTION_TIMEOUT: float = 3.0

var primary:Color 
var secondary:Color

# Signals to let the GUI know what's happening
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# --- HOSTING (The P2P "Server" Player) ---
func host_game():
	var peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT)
	if error != OK:
		print("cannot host: " + error_string(error))
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	print("Waiting for players...")
	change_level.call_deferred(LEVEL_SCENE_PATH)
	# Optional: Setup UPnP to allow internet play without manual port forwarding
	#_setup_upnp()

# --- JOINING (The Client Player) ---
func join_game(address):
	if address == "":
		address = DEFAULT_SERVER_IP
	
	var peer = ENetMultiplayerPeer.new()	
	var error = peer.create_client(address, PORT)
	if error != OK:
		print("cannot join: " + error)
		return
		
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	print("Joining...")
	
	await get_tree().create_timer(CLIENT_CONNECTION_TIMEOUT).timeout
	var status: MultiplayerPeer.ConnectionStatus = peer.get_connection_status()
	
	if status != MultiplayerPeer.CONNECTION_CONNECTED:
		print("No connection after %s seconds, start to host game..." % CLIENT_CONNECTION_TIMEOUT)
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		host_game()
	

func cleanup_network():
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	print("Network cleaned up")
	ScoreManager.game_over_signal_emmited = false
	
# --- CALLBACKS ---
func _on_player_connected(id):
	print("Player connected: " + str(id))
	# Here you usually spawn the player character
	player_connected.emit(id, {}) 

func _on_player_disconnected(id):
	print("Player disconnected: " + str(id))
	player_disconnected.emit(id)

func _on_connected_ok():
	print("Connected to server!")
	change_level.call_deferred(LEVEL_SCENE_PATH)

func _on_connected_fail():
	print("Connection failed!")
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	print("Server disconnected")
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()

# --- UPnP (Universal Plug and Play) ---
# This attempts to automatically forward ports on the router
func _setup_upnp():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPnP Discover Failed! Error %s" % discover_result)
		return

	var gateway = upnp.get_gateway()
	if !gateway or !gateway.is_valid_gateway():
		print("UPnP Invalid Gateway!")
		return

	var map_result = gateway.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPnP Port Mapping Failed! Error %s" % map_result)
	else:
		print("UPnP Success! Join Address: %s" % upnp.query_external_address())

func change_level(scene_path):
	get_tree().change_scene_to_file(scene_path)
