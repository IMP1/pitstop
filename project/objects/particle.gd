class_name ParticleSprite2D
extends MovingSprite2D

@export var lifetime: float = 2.0


func _ready() -> void:
	var tween := create_tween()
	var transparent = Color(1, 1, 1, 0)
	tween.tween_property(self, "self_modulate", transparent, lifetime)
	tween.play()
	await tween.finished
	queue_free()

