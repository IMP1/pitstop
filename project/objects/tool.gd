class_name Tool
extends CharacterBody2D

signal thrown(tool, position, velocity)

const PLAYER_COLLISION_LAYER = 1

@export var bounce_factor: float = 0.5

@onready var _grab_shape := $GrabArea/CollisionShape2D as CollisionShape2D


func grab(player: Player) -> void:
	Debug.info("[Tool] Grabbing")
	self.reparent(player._held_tools)
#	transform = player._held_tools.transform
	velocity = Vector2.ZERO
	_grab_shape.disabled = true


func throw(vel: Vector2) -> void:
	Debug.info("[Tool] Throwing")
	thrown.emit(self, global_position, vel)
	_grab_shape.disabled = false
	await get_tree().create_timer(0.5).timeout


func _physics_process(delta: float) -> void:
	if velocity == Vector2.ZERO:
		return
	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * bounce_factor
