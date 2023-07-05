class_name ShipFault
extends Interactable

signal progress_changed(value)

var progress: float = 0.0

@onready var _progress_bar := $ProgressBar as ProgressBar
@onready var _sprite := $Sprite2D as Sprite2D

# TODO: Have a completion effect? Sound / particles? Something satisfying!

