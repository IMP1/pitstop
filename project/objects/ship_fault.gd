class_name ShipFault
extends Interactable

signal progress_changed(value)

@export var icon: Texture2D
@export var todo_header: String
@export var todo_list: Array[String]

var progress: float = 0.0

@onready var _progress_bar := $ProgressBar as ProgressBar
@onready var _sprite := $Sprite2D as Sprite2D
@onready var _icon := $Icon as Sprite2D


func _ready() -> void:
	_icon.texture = icon
	_icon.visible = false


func _player_left(body: Node2D) -> void:
	if not body is Player:
		return
	var player := body as Player
	if player.device_id == _device_interacting:
		Debug.debug("[ShipFault] Player has left the area.")
		stop_interacting()


# TODO: Have a completion effect? Sound / particles? Something satisfying!

