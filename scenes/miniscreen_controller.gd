extends Control

func _on_zoomin():
	$Menu.show()
	$PRESSTART.hide()
	$Menu/VBoxContainer/HostGameBTN.grab_focus()

signal zoomout

func _zoomout():
	zoomout.emit()
