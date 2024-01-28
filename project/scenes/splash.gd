extends Node2D

@export var scene_path: String
@export var post_load_delay: float = 0.3
@export var require_input: bool = true

var _finished: bool = false

@onready var _progress := $TextureRect/ProgressBar as ProgressBar
@onready var _button := $TextureRect/Button as Button


func _ready() -> void:
	ResourceLoader.load_threaded_request(scene_path)
	_finished = false
	_button.visible = false


func _process(_delta: float) -> void:
	if _finished:
		return
	var progress := [] as Array[float]
	var status := ResourceLoader.load_threaded_get_status(scene_path, progress)
	match status:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			_complete()
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			_progress.value = progress[0]
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			_fail()
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			_fail()


func _complete():
	Debug.debug("[Splash] Loaded scene %s" % scene_path)
	_finished = true
	_progress.value = 1.0
	await create_tween().tween_interval(post_load_delay).finished
	var packed_scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if require_input:
		_button.visible = true
		_button.grab_focus()
		await _button.pressed
	get_tree().change_scene_to_packed(packed_scene)


func _fail():
	Debug.error("[Splash] Couldn't load scene %s" % scene_path)
