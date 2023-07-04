class_name Player
extends CharacterBody2D

signal accellerated(position, velocity)

const NO_DEVICE = -1
const VELOCITY_EPSILON = 1.4
const PROPULSION_PARTICLE_SPEED = 16

@export var device_id: int = NO_DEVICE
@export var colour: Color = Color.WEB_GREEN
@export var accelleration: float = 2.0
@export var braking_strength: float = 0.9
@export var bounce_factor: float = 0.9
@export var velocity_max: float = 64
@export var braking_strength_min: float = 0.8
@export var braking_strength_max: float = 0.1
@export var throw_strength: float = 64.0

@onready var _interaction_range := $InteractionRange as Area2D
@onready var _grab_range := $GrabRange as Area2D
@onready var _sprite := $Sprite2D as Sprite2D
@onready var _held_tools := $HeldTool as Node2D
@onready var _jetpack_audio := $Jetpack/Audio as AudioStreamPlayer2D


func _ready() -> void:
	if device_id >= 0:
		InputManager.register_gamepad(device_id)


func _input(event: InputEvent) -> void:
	if device_id < 0:
		return
	var grab := "grab_%d" % device_id
	var throw := "throw_%d" % device_id
	var use := "use_%d" % device_id
	if event.is_action_pressed(grab):
		_try_grab()
	if event.is_action_pressed(use):
		_try_interact()
	if event.is_action_pressed(throw):
		_try_throw()


func _try_grab() -> void:
	if _held_tools.get_child_count() > 0:
		return
	if not _grab_range.has_overlapping_areas():
		return
	var obj := _grab_range.get_overlapping_areas()[0].get_parent() as Tool
	obj.grab(self)


func _try_interact() -> void:
	if not _interaction_range.has_overlapping_areas():
		return
	var obj := _interaction_range.get_overlapping_areas()[0].get_parent() as Interactable
	obj.interact(self)


func _try_throw() -> void:
	if _held_tools.get_child_count() == 0:
		return
	var tool := _held_tools.get_child(0) as Tool
	var left := "aim_left_%d" % device_id
	var right := "aim_right_%d" % device_id
	var up := "aim_up_%d" % device_id
	var down := "aim_down_%d" % device_id
	var aim_direction := Input.get_vector(left, right, up, down)
	if aim_direction == Vector2.ZERO:
		aim_direction = velocity
	else:
		aim_direction *= throw_strength
	tool.throw(aim_direction)


func current_tool() -> Tool:
	if _held_tools.get_child_count() == 0:
		return null
	return _held_tools.get_child(0) as Tool


func has_tool(tool_name: NodePath) -> bool:
	return _held_tools.has_node(tool_name)


func get_tool(tool_name: NodePath) -> Tool:
	return _held_tools.get_node_or_null(tool_name)


func _process(delta: float) -> void:
	# TODO: Highlight which interactble would be used, if any can be.
	if device_id < 0:
		return
	var left := "move_left_%d" % device_id
	var right := "move_right_%d" % device_id
	var up := "move_up_%d" % device_id
	var down := "move_down_%d" % device_id
	var brake := "move_brake_%d" % device_id
	var movement := Input.get_vector(left, right, up, down)
	velocity += movement * accelleration
	var braking_input :=  Input.get_action_strength(brake)
	var braking_force := lerpf(braking_strength_min, braking_strength_max, braking_input)
	velocity *= pow(braking_force * braking_strength, delta)
	if velocity.length_squared() < VELOCITY_EPSILON * VELOCITY_EPSILON:
		velocity = Vector2.ZERO
	if velocity.length_squared() > velocity_max * velocity_max:
		velocity = velocity.normalized() * velocity_max
	var direction := velocity.normalized()
	if movement.x < 0:
		_sprite.flip_h = true
	if movement.x > 0:
		_sprite.flip_h = false
	if movement != Vector2.ZERO:
		accellerated.emit(position, -movement * PROPULSION_PARTICLE_SPEED, 30, colour)
	if braking_input > 0:
		var brake_amount := velocity.length() / 4
		var particle_speed := PROPULSION_PARTICLE_SPEED * clampf(brake_amount, 0, 3)
		accellerated.emit(position + direction * 6, direction * particle_speed, 60, colour)
	if (movement != Vector2.ZERO or (braking_input > 0 and velocity != Vector2.ZERO)) and not _jetpack_audio.playing:
		_jetpack_audio.play()
	if movement == Vector2.ZERO and (braking_input == 0 or velocity == Vector2.ZERO) and _jetpack_audio.playing:
		_jetpack_audio.stop()


func _physics_process(delta: float):
	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * bounce_factor
	# TODO: Copy physics from Punt to have that sweet sweet conservation of momentum

