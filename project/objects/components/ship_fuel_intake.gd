class_name FuelIntake
extends Interactable

@export var capacity: float = 100

var _visible_progress: int = 0
var show_progress: bool = false:
	get:
		return _progress_bar.visible
	set(value):
		_visible_progress += 1 if value else -1
		_progress_bar.visible = _visible_progress > 0
var fill_level: float = 0:
	get:
		return fill_level

@onready var _insertion_point := $InsertionPoint as Node2D
@onready var _attach_nozzle_audio := $AttachAudio as AudioStreamPlayer2D
@onready var _progress_bar := $ProgressBar as ProgressBar


func _ready() -> void:
	_progress_bar.max_value = capacity


func interact(player: Player) -> void:
	if player.has_tool("Nozzle"):
		_attach_nozzle(player.get_tool("Nozzle"))
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
	fill_level += amount
	_progress_bar.value += amount

