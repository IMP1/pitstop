class_name ToDoList
extends VBoxContainer

const LIST_ITEM = preload("res://gui/to_do_list_item.tscn")

var _current_id: int = -1


func add_header(text: String) -> void:
	_current_id += 1
	var label := Label.new()
	add_child(label)
	label.set_deferred("text", text)


func add_item(text: String, completed:=false) -> int:
	_current_id += 1
	var list_item := LIST_ITEM.instantiate() as ToDoListItem
	list_item.text = text
	add_child(list_item)
	if completed:
		list_item.complete.call_deferred()
	return _current_id


func complete_item(index: int) -> void:
	var list_item := get_child(index) as ToDoListItem
	list_item.complete()


func reset_item(index: int) -> void:
	var list_item := get_child(index) as ToDoListItem
	list_item.reset()
