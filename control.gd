extends Control



func _on_host_pressed() -> void:
	print("Host Pressed")
	NetworkManager.host_game()
	hide() # Hide the menu so we can see the game


func _on_join_pressed() -> void:
	print("Join Pressed")
	NetworkManager.join_game("127.0.0.1")
	hide()
