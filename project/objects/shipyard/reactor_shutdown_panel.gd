extends Node2D
class_name ReactorShutdown

signal reactor_meltdown

@export var meltdown_time: float
@export var button_discrepency_time: float
@export var panel_1: ShutdownAbortPanel
@export var panel_2: ShutdownAbortPanel

var _button_timer_running: bool
var _meltdown_occurring: bool

@onready var _button_timer := $ButtonTimer as Timer
@onready var _meltdown_timer := $MeltdownTimer as Timer


func _ready() -> void:
	_meltdown_occurring = false
	_button_timer_running = false
	_button_timer.wait_time = button_discrepency_time
	_meltdown_timer.wait_time = meltdown_time
	_button_timer.timeout.connect(_timeout)
	_meltdown_timer.timeout.connect(_meltdown)
	panel_1.button_pressed.connect(_button_pressed)
	panel_2.button_pressed.connect(_button_pressed)
	(panel_1.get_node("Sprite2D/Flash") as Node2D).visible = false
	(panel_2.get_node("Sprite2D/Flash") as Node2D).visible = false


func start_meltdown() -> void:
	_meltdown_occurring = true
	_meltdown_timer.start()
	(panel_1.get_node("Sprite2D/Flash") as Node2D).visible = true
	(panel_2.get_node("Sprite2D/Flash") as Node2D).visible = true
	panel_1.active = true
	panel_2.active = true


func _button_pressed() -> void:
	if not _meltdown_occurring:
		return
	if _button_timer_running:
		_stop_meltdown()
	else:
		_button_timer_running = true
		_button_timer.start()


func _stop_meltdown() -> void:
	_button_timer.stop()
	_button_timer_running = false
	Debug.info("[Shutdown] Phew...")
	_meltdown_occurring = false
	(panel_1.get_node("Sprite2D/Flash") as Node2D).visible = false
	(panel_2.get_node("Sprite2D/Flash") as Node2D).visible = false
	panel_1.active = false
	panel_2.active = false


func _timeout() -> void:
	_button_timer.stop()
	_button_timer_running = false
	Debug.info("[Shutdown] Cancelled")


func _meltdown() -> void:
	reactor_meltdown.emit()
	Debug.info("[Shutdown] Kaboom")
