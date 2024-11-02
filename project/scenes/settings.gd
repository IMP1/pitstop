extends Control
class_name MenuSettings

signal closed

@onready var _tab_select := $HSelect as HSelect
@onready var _tab_container := $TabContainer as TabContainer


func _set_settings_tab() -> void:
	_tab_container.current_tab = _tab_select.selected_index


func open() -> void:
	visible = true
	_tab_select.grab_focus()


func _close() -> void:
	closed.emit()
