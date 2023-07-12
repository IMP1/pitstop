class_name Interactable
extends Node2D

@export var hold_to_interact: bool = false

var _device_interacting: int


func interact(player: Player) -> void:
	Debug.info("[Interactable] Being used by %d" % player.device_id)
	_device_interacting = player.device_id


func stop_interacting() -> void:
	pass


func _input(event: InputEvent) -> void:
	var action := "use_%d" % _device_interacting
	if event.is_action_released(action) and hold_to_interact:
		stop_interacting()


func can_interact(_player: Player) -> bool:
	return true

