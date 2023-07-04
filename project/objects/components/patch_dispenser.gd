extends Interactable

signal patch_released(patch)

const PATCH_OBJECT = preload("res://objects/shipyard/patch.tscn")

@export var spawn_area: Area2D
@export var velocity: Vector2

var patches_created: int = 0


func _spawn_area_clear() -> bool:
	return not spawn_area.has_overlapping_bodies()


func interact(_player: Player) -> void:
	if _spawn_area_clear():
		Debug.info("[Dispenser] Creating patch")
		var patch := PATCH_OBJECT.instantiate() as Patch
		add_child(patch)
		patch_released.emit(patch)
		patch.global_position = spawn_area.global_position
		patch.throw(velocity)
		patches_created += 1
	else:
		Debug.info("[Dispenser] Spawn area occupied")
		# TODO: Play a buzzer?
		pass
