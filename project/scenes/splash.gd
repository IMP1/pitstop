extends Node2D

@export var scene_path: String

var _finished: bool = false

@onready var _progress := $TextureRect/ProgressBar as ProgressBar


func _ready() -> void:
	ResourceLoader.load_threaded_request(scene_path)


func _process(delta: float) -> void:
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
	var packed_scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
	get_tree().change_scene_to_packed(packed_scene)


func _fail():
	Debug.error("[Splash] Couldn't load scene %s" % scene_path)
