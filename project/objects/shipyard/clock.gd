class_name ShipyardClock
extends Node2D

signal timeout
signal timelow

@export var time_limit: float = 60
@export var warning_length: float = 10
@export var warning_colour: Color = Color.DARK_RED

@onready var _timer := $Timer as Timer
@onready var _warning_timer := $WarningTimer as Timer
@onready var _label := $Label as Label


func begin() -> void:
	_timer.start(time_limit)
	_warning_timer.start(time_limit - warning_length)


func stop() -> void:
	_timer.paused = true
	_warning_timer.paused = true


func time_left() -> float:
	return _timer.time_left


func _process(_delta: float) -> void:
	var minutes := int(_timer.time_left / 60)
	var seconds := int(_timer.time_left) % 60
	_label.text = "%02d:%02d" % [minutes, seconds]


func _timelow() -> void:
	timelow.emit()
	_label.add_theme_color_override("font_color", warning_colour)


func _timeout() -> void:
	timeout.emit()
