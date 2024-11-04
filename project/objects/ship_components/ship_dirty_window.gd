extends ShipFault
class_name DirtyWindow

@export var time_to_clean: float = 2.4

var _is_finished: bool = false
var _is_cleaning: bool = false
var _cleanliness: float = 0

@onready var _window := $Window as Polygon2D
@onready var _dirt_shader := _window.material as ShaderMaterial
@onready var _audio := $Squeaks as AudioStreamPlayer2D


func _ready():
	super()


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
	_audio.play()


func stop_interacting() -> void:
	_is_cleaning = false
	_audio.stop()


func _process(delta: float) -> void:
	if not _is_cleaning:
		return
	if _is_finished:
		return
	_cleanliness += delta
	var old_progress := progress
	var new_progress := _cleanliness / time_to_clean
	var emit_particles := false
	if floori(new_progress / 0.25) % 2 != floori(progress / 0.25) % 2:
		emit_particles = true
	progress = new_progress
	_dirt_shader.set_shader_parameter(&"progress", progress)
	if emit_particles:
		# TODO: This is completely coupled with the current progress gradient image
		var colours := (_window.texture as NoiseTexture2D).color_ramp
		var colour := colours.sample(randf())
		var pos := _window.global_position + (Vector2.DOWN * _window.texture.get_height() * snappedf(old_progress, 0.25))
		var direction := floori(old_progress / 0.25) % 2
		var vel := Vector2.RIGHT * 12
		vel.x += -24 * direction
		pos.x += _window.texture.get_width() * (1 - direction)
		var game := get_node("/root/Game") as GameScene
		for i in 20:
			game._add_particle(pos + Vector2.DOWN * randf_range(-1, 1) * 6 + Vector2.RIGHT * randf_range(-1, 1), vel, 5, colour, 0.8)
	# TODO: Play a squeaky noise?
	if _cleanliness >= time_to_clean:
		_cleanliness = time_to_clean
		_is_finished = true
	progress_changed.emit(progress)
