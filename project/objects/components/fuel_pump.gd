extends Interactable

var _last_nozzle_position: Vector2
var _nozzle_initial_position: Vector2

@onready var _nozzle := $Nozzle as Nozzle
@onready var _pipe := $Pipe as Line2D
@onready var _grab_sound := $GrabNozzleAudio as AudioStreamPlayer2D
@onready var _drop_sound := $DropNozzleAudio as AudioStreamPlayer2D


func _ready() -> void:
	_nozzle_initial_position = _nozzle.position
	_last_nozzle_position = _pipe.get_point_position(1)
	_nozzle.set_highlight(false)


func interact(player: Player) -> void:
	if has_node("Nozzle"):
		_nozzle_taken(player)
	elif player.current_tool() is Nozzle:
		_nozzle_returned()


func _nozzle_taken(player: Player) -> void:
	Debug.info("[Fuel Pump] Take Nozzle")
	_grab_sound.play()
	_nozzle.grab(player)


func _nozzle_returned() -> void:
	Debug.info("[Fuel Pump] Recieve Nozzle")
	_drop_sound.play()
	_nozzle.reparent(self)
	_nozzle.position = _nozzle_initial_position
	_nozzle.velocity = Vector2.ZERO


func _process(delta: float) -> void:
	if _nozzle.position == _nozzle_initial_position:
		return
	_extend_pipe(delta)


func _extend_pipe(_delta: float) -> void:
	var pos := _pipe.to_local(_nozzle.global_position)
	var movement := pos - _last_nozzle_position
	if pos.distance_squared_to(_last_nozzle_position) > 64:
		_pipe.add_point(pos, _pipe.get_point_count() - 1)
		_last_nozzle_position = pos
	_pipe.set_point_position(_pipe.get_point_count() - 1, pos)
	_nozzle.rotation = movement.angle() + deg_to_rad(225)
