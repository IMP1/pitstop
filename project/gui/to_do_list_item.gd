class_name ToDoListItem
extends HBoxContainer

@export var text: String = ""

@onready var _checkbox := $CheckBox as CheckBox


func _ready() -> void:
	_checkbox.text = text


func set_text(new_text: String) -> void:
	text = new_text
	_checkbox.text = text


func complete() -> void:
	_checkbox.set_pressed_no_signal(true)


func reset() -> void:
	_checkbox.set_pressed_no_signal(false)
