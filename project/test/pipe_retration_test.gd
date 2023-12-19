extends Node2D

@export var target: Node2D
@export var anchor: Node2D
@export var line: Line2D
@export var speed: float = 16


func _ready() -> void:
	# get shortest possible path
	var min_path := target.position - anchor.position
	var min_dist := min_path.length()
	
	#print(min_dist)
	var index: int = line.get_point_count()
	var dist: float = 0
	for j in line.get_point_count() - 1:
		var i := line.get_point_count() - j - 1
		dist += (line.get_point_position(i-1) - line.get_point_position(i)).length()
		index = i
		if dist >= min_dist:
			break
	#print(index)
	#print(dist)
