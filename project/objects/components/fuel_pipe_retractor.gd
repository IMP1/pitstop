extends Interactable

@export var pipe: Line2D
@export var nozzle: Nozzle
@export var nozzle_slot: Interactable
@export var hold_to_interact: bool = true
@export var retraction_speed: float = 1.0
@export var loose_tool_container: Node2D

var _retracting: bool = false
var _device_interacting: int
var _last_retraction_direction: Vector2

@onready var _raycast := $RayCast2D as RayCast2D
@onready var _audio := $AudioStreamPlayer2D as AudioStreamPlayer2D


func interact(player: Player) -> void:
	if not _retracting:
		_start_retracting(player.device_id)
	elif not hold_to_interact:
		_stop_retracting()


func _input(event: InputEvent) -> void:
	if not _retracting:
		return
	var action := "use_%d" % _device_interacting
	if event.is_action_released(action) and hold_to_interact:
		_stop_retracting()


func _start_retracting(device_id: int) -> void:
	Debug.info("[Fuel Pipe Retractor] Engaging")
	_retracting = true
	_device_interacting = device_id
	nozzle.velocity = Vector2.ZERO
	_audio.play()


func _stop_retracting() -> void:
	Debug.info("[Fuel Pipe Retractor] Disengaging")
	_retracting = false
	nozzle.velocity = _last_retraction_direction.normalized() * retraction_speed * 0.2
	_audio.stop()


func _is_nozzle_fixed() -> bool:
	return not (nozzle.get_parent() is Player or nozzle.get_parent() == loose_tool_container)


func _process(delta: float) -> void:
	if not _retracting:
		return
	if _is_nozzle_fixed():
		_retract_fixed(delta)
	else:
		_retract_end(delta)

func _retract_end(delta: float) -> void:
	# Just move along the line removing points along the way
	var distance := retraction_speed * delta
	while distance > 0:
		if pipe.get_point_count() == 3:
			_stop_retracting()
			nozzle_slot._nozzle_returned()
			return
		var next_move := pipe.get_point_position(pipe.get_point_count() - 2) - pipe.to_local(nozzle.global_position)
		_last_retraction_direction = next_move
		var move_distance := minf(distance, next_move.length())
		nozzle.move_and_collide(next_move.normalized() * move_distance)
		distance -= move_distance
		if pipe.get_point_position(pipe.get_point_count() - 2) == pipe.to_local(nozzle.global_position):
			pipe.remove_point(pipe.get_point_count() - 2)


func _retract_fixed(delta: float) -> void:
	var distance := retraction_speed * delta
	# TODO: Do something complicated - Look up string pulling algorithms? Is that a thing?
	pass
