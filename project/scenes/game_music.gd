extends Node

@export var autoplay: bool
@export var tracks: Array[AudioStream]
@export var shuffle: bool = true
@export var cross_fade_duration: float = 1.0

var _current_track: int
var _next_tracks: Array[int] = []


func _ready() -> void:
	MusicManager.track_finished.connect(_next_track)
	if autoplay:
		_next_track()


func _populate_queue() -> void:
	_next_tracks = []
	for i in tracks.size():
		_next_tracks.append(i)
	if shuffle:
		_next_tracks.shuffle()


func _next_track() -> void:
	if _next_tracks.is_empty():
		_populate_queue()
	_current_track = _next_tracks.pop_front()
	MusicManager.blend_to(tracks[_current_track], cross_fade_duration)
