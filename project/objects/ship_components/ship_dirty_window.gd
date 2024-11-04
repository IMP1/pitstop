extends ShipFault
class_name DirtyWindow

@export var time_to_clean: float = 2.4

var _is_finished: bool = false
var _is_cleaning: bool = false
var _cleanliness: float = 0

@onready var _dirt_shader := ($Window as Polygon2D).material as ShaderMaterial


func _ready():
	super()
	#_offset = Vector2.from_angle(randf_range(0, TAU)) * randf_range(6, 20)
	#_progress_bar.max_value = _offset.length_squared()


func can_interact(player: Player) -> bool:
	if _is_finished:
		return false
	if not player.current_tool() is Squeegee:
		return false
	return true


func interact(player: Player) -> void:
	if not can_interact(player):
		return
	_device_interacting = player.device_id
	_is_cleaning = true


func _process(delta: float) -> void:
	if not _is_cleaning:
		return
	if _is_finished:
		return
	_cleanliness += delta
	progress = _cleanliness / time_to_clean
	_dirt_shader.set_shader_parameter(&"progress", progress)
	if _cleanliness >= time_to_clean:
		_cleanliness = time_to_clean
		_is_finished = true
	progress_changed.emit(progress)
