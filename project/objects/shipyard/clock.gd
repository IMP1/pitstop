extends Node2D

signal timeout
signal timelow

@export var _time_limit: float = 60
@export var _warning_length: float = 10

@onready var _timer := $Timer as Timer
@onready var _warning_timer := $WarningTimer as Timer
@onready var _label := $Label as Label


func begin() -> void:
	_timer.start(_time_limit)
	_warning_timer.start(_time_limit - _warning_length)


func _process(_delta: float) -> void:
	var minutes := int(_timer.time_left / 60)
	var seconds := int(_timer.time_left) % 60
	_label.text = "%02d:%02d" % [minutes, seconds]


func _timelow() -> void:
	timelow.emit()


func _timeout() -> void:
	timeout.emit()

