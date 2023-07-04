extends CanvasLayer

@onready var _label := $Panel/Label as Label

enum Severity { NONE, ERROR, WARNING, INFO, DEBUG, TRACE }

var severity_level := Severity.INFO


func _ready() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible


func _write(message, importance: Severity) -> void:
	if severity_level < importance:
		return
	print(message)
	_label.text += str(message) + "\n"
	_label.lines_skipped = maxi(0, _label.text.count("\n") - _label.max_lines_visible)
	_label.queue_redraw()


func error(message) -> void:
	_write(message, Severity.ERROR)

func warning(message) -> void:
	_write(message, Severity.WARNING)

func info(message) -> void:
	_write(message, Severity.INFO)

func debug(message) -> void:
	_write(message, Severity.DEBUG)

func trace(message) -> void:
	_write(message, Severity.TRACE)


