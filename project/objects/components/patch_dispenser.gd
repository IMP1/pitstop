class_name PatchDispenser
extends Interactable

signal patch_released(patch)

const PATCH_OBJECT = preload("res://objects/shipyard/patch.tscn")

@export var velocity: Vector2
@export var patch_price: float = 10.0
@export var recycled_patch_cost_reclaimed: float = 8.0

var patches_created: int = 0

@onready var spawn_area := $Output as Area2D


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
