class_name FuelIntake
extends ShipFault

@export var capacity: float = 100

var _visible_progress: int = 0
var show_progress: bool = false:
	get:
		return _progress_bar.visible
	set(value):
		_visible_progress += 1 if value else -1
		_progress_bar.visible = _visible_progress > 0
var fill_level: float = 0

@onready var _insertion_point := $InsertionPoint as Node2D
@onready var _attach_nozzle_audio := $AttachAudio as AudioStreamPlayer2D


func _ready() -> void:
	super()
	_progress_bar.max_value = capacity


func interact(player: Player) -> void:
	if player.current_tool() is Nozzle:
		_attach_nozzle(player.current_tool())
	elif has_node("Nozzle"):
		_detach_nozzle(player)


func _attach_nozzle(nozzle: Tool) -> void:
	_attach_nozzle_audio.play()
	nozzle.reparent(self)
	nozzle.transform = _insertion_point.transform 


func _detach_nozzle(player: Player) -> void:
	_attach_nozzle_audio.play()
	(get_node("Nozzle") as Tool).grab(player)


func pump(amount: float) -> void:
	if fill_level >= capacity:
		return
	fill_level += amount
	_progress_bar.value = fill_level
	Debug.trace("[Fuel Intake] Level at %.2f (%.2f%%)" % [fill_level, _progress_bar.value / _progress_bar.max_value])
	progress_changed.emit(_progress_bar.value / _progress_bar.max_value)
	if _progress_bar.value / _progress_bar.max_value >= 1.0:
		Debug.info("[Fuel Intake] Fuel full")

