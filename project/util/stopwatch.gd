class_name Stopwatch
extends Node

var laps: Array[float] = []
var time: float = 0
var current_lap: float = 0
var _running: bool = false


func reset() -> void:
	time = 0
	current_lap = 0
	laps.clear()


func start() -> void:
	_running = true


func stop() -> void:
	_running = false


func lap() -> void:
	laps.append(current_lap)
	current_lap = 0


func _process(delta: float) -> void:
	if not _running:
		return
	time += delta
	current_lap += delta
