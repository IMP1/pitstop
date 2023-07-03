extends CanvasLayer

@onready var _label := $Panel/Label as Label

enum Severity { NONE, ERROR, WARNING, INFO, TRACE }

var severity_level := Severity.INFO


func _ready() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible


func _write(message) -> void:
	print(message)
	_label.text += str(message) + "\n"
	_label.lines_skipped = maxi(0, _label.text.count("\n") - _label.max_lines_visible)
	_label.queue_redraw()


func error(message) -> void:
	if severity_level < Severity.ERROR:
		return
	_write(message)

func warning(message) -> void:
	if severity_level < Severity.INFO:
		return
	_write(message)

func info(message) -> void:
	if severity_level < Severity.INFO:
		return
	_write(message)

func trace(message) -> void:
	if severity_level < Severity.TRACE:
		return
	_write(message)


