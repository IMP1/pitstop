extends Interactable
class_name ShutdownAbortPanel

signal button_pressed

@export var active: bool = false
@export var highlight_line: Line2D


func interact(_player: Player) -> void:
	button_pressed.emit()


func can_interact(_player: Player) -> bool:
	return active


func highlight(colour: Color) -> void:
	highlight_line.default_color = colour
