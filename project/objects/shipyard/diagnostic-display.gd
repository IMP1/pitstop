class_name DiagnosticDisplay
extends Interactable

const OFF_FRAME = 5
const ON_FRAME = 0
const NO_SHIP_FRAME = 1

var _ship: Ship
var _showing_jobs: bool = false

@onready var _sprite := $Sprite2D as Sprite2D
@onready var _todo_list := $ToDoList as ToDoList


func _ready() -> void:
	_sprite.frame = NO_SHIP_FRAME
	_todo_list.visible = false


func set_ship(ship: Ship) -> void:
	_ship = ship
	_populate_todo_list()


func add_ship() -> void:
	var tween := create_tween()
	tween.tween_interval(1.0)
	_sprite.frame = NO_SHIP_FRAME
	tween.tween_property(_sprite, "frame", OFF_FRAME, 1.0)


func remove_ship() -> void:
	for component in _ship._components.get_children():
		if component is ShipFault:
			(component as ShipFault)._icon.visible = false
	var tween := create_tween()
	tween.tween_interval(1.0)
	_sprite.frame = OFF_FRAME
	tween.tween_property(_sprite, "frame", NO_SHIP_FRAME, 1.0)


func _populate_todo_list() -> void:
	for fault in _ship.get_faults():
		Debug.info("[Diagnostic] Fault: %s" % str(fault))
		_todo_list.add_header(fault.todo_header)
		for item in fault.todo_list:
			_todo_list.add_item(item)
	# TODO: Link list items/headers with ship faults graphically?
	#       With lines overlayed, or matching icons


func interact(_player: Player) -> void:
	if not _ship:
		Debug.info("[Diagnostic] No ship connected")
		return
	_showing_jobs = not _showing_jobs
	Debug.debug("[Diagnostic] Toggling %s" % ("on" if _showing_jobs else "off"))
	for component in _ship.get_faults():
		(component as ShipFault)._icon.visible = _showing_jobs
	# TODO: Draw lines to link faults to tools?
	_sprite.frame = ON_FRAME if _showing_jobs else OFF_FRAME
	_todo_list.visible = _showing_jobs

