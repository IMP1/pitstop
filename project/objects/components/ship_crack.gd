class_name HullCrack
extends Interactable

signal progress_changed(value)

const UNPATCHED_FRAME = 0
const PATCHED_FRAME = 1

@export var time_to_patch: float = 2.0

var _has_patch: bool = false
var _is_welding: bool = false
var _device_interacting: int
var _is_finished: bool = false

@onready var _sprite := $Sprite2D as Sprite2D
@onready var _progress_bar := $ProgressBar as ProgressBar
@onready var _welding_audio := $WeldingAudio as AudioStreamPlayer2D


func _ready():
	_sprite.frame = UNPATCHED_FRAME
	_progress_bar.visible = false
	_progress_bar.max_value = time_to_patch


func interact(player: Player) -> void:
	if _is_finished:
		return
	if not _has_patch and player.current_tool() is Patch:
		_apply_patch(player.get_tool("Patch"))
	elif _has_patch and player.current_tool() is Blowtorch:
		_start_welding(player.device_id)


func _input(event: InputEvent) -> void:
	if _is_finished:
		return
	if not _is_welding:
		return
	var action := "use_%d" % _device_interacting
	if event.is_action_released(action):
		_stop_welding()


func _apply_patch(patch: Tool) -> void:
	patch.queue_free()
	_has_patch = true
	_sprite.frame = PATCHED_FRAME
	_progress_bar.visible = true


func _start_welding(device_id: int) -> void:
	_device_interacting = device_id
	_is_welding = true
	_welding_audio.play()


func _stop_welding() -> void:
	_is_welding = false
	_welding_audio.stop()


func _process(delta: float) -> void:
	if not _is_welding:
		return
	if _is_finished:
		return
	# TODO: Emit some particles?
	_progress_bar.value += delta
	_sprite.modulate.a = lerpf(1, 0, _progress_bar.value / _progress_bar.max_value)
	if _progress_bar.value >= _progress_bar.max_value:
		_progress_bar.value = _progress_bar.max_value
		_is_finished = true
		_welding_audio.stop()
	progress_changed.emit(_progress_bar.value / _progress_bar.max_value)
