extends Interactable
class_name ShutdownAbortPanel

signal button_pressed


func interact(_player: Player) -> void:
	button_pressed.emit()
