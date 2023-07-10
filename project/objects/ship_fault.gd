class_name ShipFault
extends Interactable

signal progress_changed(value)

@export var icon: Texture2D

var progress: float = 0.0

@onready var _progress_bar := $ProgressBar as ProgressBar
@onready var _sprite := $Sprite2D as Sprite2D
@onready var _icon := $Icon as Sprite2D


func _ready() -> void:
	_icon.texture = icon
	_icon.visible = false

# TODO: Have a completion effect? Sound / particles? Something satisfying!

