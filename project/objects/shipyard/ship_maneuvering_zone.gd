extends Area2D

@export var hazard_icon: Texture2D
@export var hazard_colour: Color
@export var hazard_z_index: int = 0
@export var hazard_offset: Vector2 = Vector2(0, -10)

var _hazard_nodes: Dictionary = {}
var _hazard_sprites: Dictionary = {}

@onready var _hazard_indicators := $HazardIndicators as Node2D
@onready var _instruction_label := $Label as Label


func show_hazards() -> void:
	_hazard_indicators.visible = true


func hide_hazards() -> void:
	_hazard_indicators.visible = false


func _body_entered(node: Node2D) -> void:
	Debug.debug("[SMZ] Body Entered (%s)" % node.name)
	var sprite := Sprite2D.new()
	_hazard_indicators.add_child(sprite)
	sprite.texture = hazard_icon
	sprite.modulate = hazard_colour
	sprite.z_index = hazard_z_index
	sprite.scale = Vector2(0.03, 0.03)
	_hazard_nodes[sprite] = node
	_hazard_sprites[node] = sprite


func _body_exited(node: Node2D) -> void:
	Debug.debug("[SMZ] Body Exited (%s)" % node.name)
	if _hazard_sprites.has(node):
		var sprite := _hazard_sprites[node] as Sprite2D
		_hazard_nodes.erase(sprite)
		_hazard_sprites.erase(node)
		sprite.queue_free()


func _process(_delta) -> void:
	for sprite in _hazard_indicators.get_children():
		if _hazard_nodes.has(sprite):
			var node: Node2D = _hazard_nodes[sprite]
			sprite.global_position = node.global_position + hazard_offset
		else:
			Debug.error("[SMZ] There was a warning icon sprite not in the dictionary")
	_instruction_label.visible = has_overlapping_bodies()

