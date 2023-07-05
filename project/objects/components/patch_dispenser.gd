class_name PatchDispenser
extends Interactable

signal patch_released(patch)

const PATCH_OBJECT = preload("res://objects/shipyard/patch.tscn")

@export var velocity: Vector2 = Vector2.ZERO
@export var patch_price: float = 10.0
@export var recycled_patch_cost_reclaimed: float = 8.0

var patches_created: int = 0

@onready var _spawn_area := $Output as Area2D
@onready var _input := $Input as Node2D
@onready var _generation_audio := $Generation as AudioStreamPlayer2D#
@onready var _failure_audio := $Failure as AudioStreamPlayer2D


func _spawn_area_clear() -> bool:
	return not _spawn_area.has_overlapping_bodies()


func interact(_player: Player) -> void:
	if _spawn_area_clear():
		_generation_audio.play()
		patches_created += 1
		Debug.info("[Dispenser] Creating patch")
		var patch := PATCH_OBJECT.instantiate() as Patch
		add_child(patch)
		patch_released.emit(patch)
		patch.global_position = _input.global_position
		var tween := create_tween()
		tween.tween_property(patch, "global_position", _spawn_area.global_position, 1.0)
		await tween.finished
		patch.throw(velocity)
	else:
		Debug.info("[Dispenser] Spawn area occupied")
		_failure_audio.play()
