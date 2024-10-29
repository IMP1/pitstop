class_name ToolStation
extends Node2D


func release_tools() -> void:
	for tool in get_children():
		if tool is Tool:
			(tool as Tool).throw(Vector2.ZERO)
