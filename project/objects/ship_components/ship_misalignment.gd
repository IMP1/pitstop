class_name ShipMisalignment
extends ShipFault

const ALIGN_SPEED := 8
const EPSILON = 1.5
const GUI_RADIUS := 12

var _is_aligning: bool = false
var _is_finished: bool = false
var _offset: Vector2

@onready var _audio := $AligningAudio as AudioStreamPlayer2D
@onready var _success_audio := $SuccessAudio as AudioStreamPlayer2D


func _ready():
	super()
	_offset = Vector2.from_angle(randf_range(0, TAU)) * randf_range(6, 20)
	_progress_bar.max_value = _offset.length_squared()


func can_interact(player: Player) -> bool:
	if _is_finished:
		return false
	if player.current_tool():
		return false
	return true


func interact(player: Player) -> void:
	if not can_interact(player):
		return
	_start_aligning(player)


func stop_interacting() -> void:
	_stop_aligning()


func _start_aligning(player: Player) -> void:
	_device_interacting = player.device_id
	_is_aligning = true
	custom_interact_icon = InputManager.get_icon(InputMap.action_get_events(&"aim_left_%d" % _device_interacting)[0])
	player._update_interactable()
	_audio.play()


func _stop_aligning() -> void:
	if not _is_aligning:
		return
	_audio.stop()
	_is_aligning = false
	custom_interact_icon = null
	queue_redraw()


func _get_alignment_input() -> Vector2:
	var action_up := "aim_up_%d" % _device_interacting
	var action_left := "aim_left_%d" % _device_interacting
	var action_down := "aim_down_%d" % _device_interacting
	var action_right := "aim_right_%d" % _device_interacting
	return Input.get_vector(action_left, action_right, action_up, action_down)


func _process(delta: float) -> void:
	if not _is_aligning:
		return
	if _is_finished:
		return
	var motion := _get_alignment_input()
	if motion != Vector2.ZERO and not _audio.playing:
		_audio.play()
	elif motion == Vector2.ZERO and _audio.playing:
		_audio.stop()
	_offset += motion * ALIGN_SPEED * delta
	var dist := _offset.length_squared()
	Debug.trace("[Ship Misallignment] " + str(_offset))
	Debug.trace("[Ship Misallignment] " + str(dist))
	_progress_bar.value = _progress_bar.max_value - dist
	progress = _progress_bar.value / _progress_bar.max_value
	if dist <= EPSILON * EPSILON:
		dist = 0
		_offset = Vector2.ZERO
		_audio.stop()
		_success_audio.play()
		_progress_bar.value = _progress_bar.max_value
		_sprite.visible = false
		_is_finished = true
		progress = 1.0
	queue_redraw()
	progress_changed.emit(progress)


func _draw() -> void:
	if not _is_aligning:
		return
	if _is_finished:
		draw_arc(Vector2.ZERO, GUI_RADIUS, 0, TAU, 16, Color.AQUAMARINE, 2)
		draw_arc(Vector2.ZERO, 3, 0, TAU, 16, Color.AQUAMARINE, 2)
		draw_circle(Vector2.ZERO, 3, Color.CRIMSON)
		return
	draw_arc(Vector2.ZERO, GUI_RADIUS, 0, TAU, 16, Color.AQUAMARINE, 2)
	draw_arc(Vector2.ZERO, 3, 0, TAU, 16, Color.AQUAMARINE, 2)
	var pos := _offset
	if pos.length_squared() > GUI_RADIUS * GUI_RADIUS:
		pos = pos.normalized() * GUI_RADIUS
	draw_circle(pos, 3, Color.CRIMSON)
