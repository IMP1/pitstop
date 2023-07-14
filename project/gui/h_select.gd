class_name HSelect
extends Button

@export var selected_index: int = 1
@export_category("Selected Item")
@export var selected_item_style: StyleBox
@export var selected_item_text_colour: Color
@export_category("Unselected Items")
@export var unselected_item_style: StyleBox
@export var unselected_item_text_colour: Color

@onready var _options := $Options as Control


func _ready() -> void:
	grab_click_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		next()
	if event.is_action_pressed("ui_left"):
		prev()


func prev() -> void:
	var last := _options.get_child(_options.get_child_count() - 1)
	_options.move_child(last, 0)


func next() -> void:
	var first := _options.get_child(0)
	_options.move_child(first, _options.get_child_count() - 1)

