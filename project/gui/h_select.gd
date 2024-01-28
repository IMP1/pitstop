class_name HSelect
extends HBoxContainer

signal selection_changed

@export var selected_index: int = 0
@export_category("Styling")
@export var selected_item_style: StyleBox
@export var selected_item_text_colour: Color
@export var unselected_item_style: StyleBox
@export var unselected_item_text_colour: Color#
@export var prev_texture: Texture2D
@export var next_texture: Texture2D

@onready var _options := self as Control

# TODO: Handle an even number of options somehow


func _ready() -> void:
	var n := _options.get_child_count()
	if n == 0:
		return
	for i in n:
		if not _options.get_child(i) is Button:
			Debug.error("[HSelect] Option #%d is not a button" % i)
			continue
		var option := _options.get_child(i) as Button
		option.focus_entered.connect(_select_item.bind(i))
		option.focus_neighbor_left = _options.get_child( (i - 1) % n).get_path()
		option.focus_neighbor_right = _options.get_child( (i + 1) % n).get_path()
		if unselected_item_style:
			option.add_theme_stylebox_override(&"normal", unselected_item_style)
		if unselected_item_text_colour:
			option.add_theme_color_override(&"font_color", unselected_item_text_colour)
		if selected_item_style:
			option.add_theme_stylebox_override(&"focus", selected_item_style)
		if selected_item_text_colour:
			option.add_theme_color_override(&"font_focus_color", selected_item_text_colour)
	(_options.get_child(selected_index) as Control).grab_focus()
	for i in floori(n / 2.0):
		_options.move_child(_options.get_child(n - 1), 0)


func _focus_entered() -> void:
	Debug.info("[HSelect] Focus gained")
	var mid_point := floori(_options.get_child_count() / 2.0)
	(_options.get_child(mid_point) as Control).grab_focus()


func _select_item(index: int) -> void:
	Debug.debug("[HSelect] Item #%d selected" % index)
	var offset := index - selected_index
	if offset == 0:
		return
	selected_index = index
	var last_index := _options.get_child_count() - 1
	for i in absi(offset):
		if offset < 0:
			_options.move_child(_options.get_child(last_index), 0)
		else:
			_options.move_child(_options.get_child(0), last_index)
	#for option in _options.get_children():
		#(option as Control).focus_mode = Control.FOCUS_NONE
	var mid_point := floori(_options.get_child_count() / 2.0)
	(_options.get_child(mid_point) as Control).grab_focus()
	selection_changed.emit()


func _draw() -> void:
	pass # TODO: Draw right and left arrows?
	#draw_texture(prev_texture, Vector2(-96, 0))
	#draw_texture(next_texture, Vector2(96, 0))
