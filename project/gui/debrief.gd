class_name Debrief
extends CanvasLayer

signal confirmed

@export var negative_colour: Color = Color.DARK_RED
@export var result: String: 
	set = _set_result

var _running_total: float = 0.0
var _confirmation_devices: Dictionary = {}

@onready var _result := $Contents/Result as Label
@onready var _tally := $Contents/Tally as VBoxContainer 
@onready var confirmation := $Contents/GroupConfirmable as GroupConfirmable


func _set_result(new_result: String) -> void:
	_result.text = new_result


func _add_item(message: String, amount: float, loss:=false) -> void:
	var hbox := HBoxContainer.new()
	_tally.add_child(hbox)
	var ref := Label.new()
	hbox.add_child(ref)
	ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ref.size_flags_horizontal += Control.SIZE_EXPAND
	ref.size_flags_stretch_ratio = 5
	ref.text = message
	
	var cost := Label.new()
	hbox.add_child(cost)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.size_flags_horizontal += Control.SIZE_EXPAND
	if loss:
		cost.add_theme_color_override("font_color", negative_colour)
		cost.text = "-£%.2f" % amount
	else:
		cost.text = "£%.2f" % amount


func add_gain(message: String, amount: float) -> void:
	_running_total += amount
	_add_item(message, amount)


func add_loss(message: String, amount: float) -> void:
	_running_total -= amount
	_add_item(message, amount, true)


func add_break() -> void:
	_tally.add_spacer(false)


func add_total(message: String = "Total") -> void:
	_add_item(message, absf(_running_total), _running_total < 0)
