extends Interactable

signal patch_released(patch, position, velocity)

@export var output: Node2D
@export var velocity: Vector2
@export var patch: Tool


func interact(_player: Player) -> void:
	Debug.info("[Dispenser] Creating Patch")
	var new_patch := patch
	patch_released.emit(new_patch, output.global_position, velocity)
	new_patch.global_position = output.global_position
