class_name MovingSprite2D
extends Sprite2D

@export var velocity: Vector2
@export var scroll: bool = false
@export var scroll_bounds: Rect2


func _process(delta: float) -> void:
	position += velocity * delta
	if scroll and not scroll_bounds.has_point(position):
		if position.x < scroll_bounds.position.x:
			position.x += scroll_bounds.size.x;
		elif position.x > scroll_bounds.end.x:
			position.x -= scroll_bounds.size.x;
		if position.y < scroll_bounds.position.y:
			position.y += scroll_bounds.size.y;
		elif position.y > scroll_bounds.end.y:
			position.y -= scroll_bounds.size.y;
