extends Node2D
class_name ReactorShutdown

signal reactor_shutdown

@export var meltdown_time: float
@export var button_discrepency_time: float
@export var panel_1: ShutdownAbortPanel
@export var panel_2: ShutdownAbortPanel

var timer_running: bool

@onready var _button_timer := $ButtonTimer as Timer
@onready var _meltdown_timer := $MeltdownTimer as Timer


func _ready() -> void:
	timer_running = false
	_button_timer.wait_time = button_discrepency_time
	_meltdown_timer.wait_time = meltdown_time
	_button_timer.timeout.connect(_timeout)
	panel_1.button_pressed.connect(_button_pressed)
	panel_2.button_pressed.connect(_button_pressed)


func start_meltdown() -> void:
	_meltdown_timer.start()
	panel_1.get_node("Sprite2D/Flash").visible = true
	panel_2.get_node("Sprite2D/Flash").visible = true


func _button_pressed() -> void:
	if timer_running:
		timer_running = false
		_button_timer.stop()
		_stop_shutdown()
	else:
		timer_running = true
		_button_timer.start()


func _stop_shutdown() -> void:
	Debug.info("[Shutdown] Phew...")


func _timeout() -> void:
	timer_running = false
	Debug.info("[Shutdown] Kaboom")


func _shutdown() -> void:
	reactor_shutdown.emit()
