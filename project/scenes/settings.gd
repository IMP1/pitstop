extends Control

signal closed

@onready var _tab_select := $HSelect as HSelect
@onready var _tab_container := $TabContainer as TabContainer


func _set_settings_tab() -> void:
	_tab_container.current_tab = _tab_select.selected_index


func _close() -> void:
	closed.emit()
