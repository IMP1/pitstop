class_name Player
extends BounceBody2D

signal accellerated(position: Vector2, velocity: Vector2, spread: float, colour: Color)

const NO_DEVICE = -1
const VELOCITY_EPSILON = 1.4
const PROPULSION_PARTICLE_SPEED = 16
const FACING_DIRECTION_WEIGHTING = 16 # Affects tool grabbing

@export var device_id: int = NO_DEVICE
@export var colour: Color = Color.WEB_GREEN
@export var accelleration: float = 2.0
@export var braking_strength: float = 0.9
@export var velocity_max: float = 64
@export var braking_strength_min: float = 0.8
@export var braking_strength_max: float = 0.1
@export var throw_strength: float = 60.0

var _direction: Vector2
var _potential_grab: Tool
var _potential_interact: Interactable

@onready var _interaction_range := $InteractionRange as Area2D
@onready var _grab_range := $GrabRange as Area2D
@onready var _sprite := $Sprite2D as Sprite2D
@onready var _shadow := $Sprite2D/Shadow as Sprite2D
@onready var _held_tool_pivot := $HeldToolPivot as Node2D
@onready var _held_tools := $HeldToolPivot/HeldTool as Node2D
@onready var _jetpack_audio := $Jetpack/Audio as AudioStreamPlayer2D
@onready var _bump_audio := $BumpAudio as AudioStreamPlayer2D
@onready var _interact_prompt := $InputPromptInteract as Sprite2D
@onready var _grab_prompt := $GrabPromptInteract as Sprite2D
@onready var _throw_pivot := $ThrowArrowPivot as Node2D
@onready var _throw_sprite := $ThrowArrowPivot/Sprite2D as Sprite2D


func set_sprite(tex: Texture2D) -> void:
	_sprite.texture = tex
	_shadow.texture = tex


func set_colour(new_colour: Color) -> void:
	colour = new_colour
	_throw_sprite.modulate = colour


func _ready() -> void:
	if device_id >= 0:
		InputManager.register_gamepad(device_id)
	_interact_prompt.visible = false
	_grab_prompt.visible = false
	_throw_pivot.visible = false
	_throw_sprite.modulate = colour


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
	var obj := _get_nearest_tool()
	obj.grab(self)
	obj.set_deferred("transform", _held_tools.transform)


func _get_nearest_tool() -> Tool:
	var nearest_tool: Tool = null
	var nearest_distance_squared: float = 0
	for obj in _grab_range.get_overlapping_areas():
		var tool := obj.get_parent() as Tool
		var vector := tool.global_position - global_position
		var dist_squared := vector.length_squared()
		if vector.dot(_direction) > 0:
			dist_squared /= FACING_DIRECTION_WEIGHTING
		if nearest_tool == null or dist_squared < nearest_distance_squared:
			nearest_tool = tool
			nearest_distance_squared = dist_squared
	return nearest_tool


func _try_interact() -> void:
	if not _interaction_range.has_overlapping_areas():
		return
	var obj := _interaction_range.get_overlapping_areas()[0].get_parent() as Interactable
	obj.interact(self)


func _get_nearest_interactable() -> Interactable:
	var nearest_interactable: Interactable = null
	var nearest_distance_squared: float = 0
	for obj in _interaction_range.get_overlapping_areas():
		var interactable := obj.get_parent() as Interactable
		var vector := interactable.global_position - global_position
		var dist_squared := vector.length_squared()
		if vector.dot(_direction) > 0:
			dist_squared /= FACING_DIRECTION_WEIGHTING
		if nearest_interactable == null or dist_squared < nearest_distance_squared:
			nearest_interactable = interactable
			nearest_distance_squared = dist_squared
	return nearest_interactable


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
	_throw_pivot.visible = false


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
	_process_movement(delta)
	_process_aim()
	_update_interactable()
	_update_grabbable()


func _process_movement(delta: float) -> void:
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
	var motion_direction := velocity.normalized()
	if movement.x < 0:
		_sprite.flip_h = true
		_shadow.flip_h = true
		_held_tool_pivot.scale.x = -1
	if movement.x > 0:
		_sprite.flip_h = false
		_shadow.flip_h = false
		_held_tool_pivot.scale.x = 1
	if movement != Vector2.ZERO:
		accellerated.emit(position, -movement * PROPULSION_PARTICLE_SPEED, 30, colour)
		_direction = movement
	if braking_input > 0:
		var brake_amount := velocity.length() / 4
		var particle_speed := PROPULSION_PARTICLE_SPEED * clampf(brake_amount, 0, 3)
		accellerated.emit(position + motion_direction * 6, motion_direction * particle_speed, 60, colour)
	if (movement != Vector2.ZERO or (braking_input > 0 and velocity != Vector2.ZERO)) and not _jetpack_audio.playing:
		_jetpack_audio.play()
	if movement == Vector2.ZERO and (braking_input == 0 or velocity == Vector2.ZERO) and _jetpack_audio.playing:
		_jetpack_audio.stop()


func _process_aim() -> void:
	if current_tool() == null:
		return
	var left := "aim_left_%d" % device_id
	var right := "aim_right_%d" % device_id
	var up := "aim_up_%d" % device_id
	var down := "aim_down_%d" % device_id
	var aim_direction := Input.get_vector(left, right, up, down)
	_throw_pivot.rotation = aim_direction.angle()
	_throw_pivot.visible = (aim_direction.length_squared() > 0.02)


func _physics_process(delta: float):
	var collision := move_and_collide(velocity * delta)
	if collision:
		_collide(collision)
		_bump_audio.play()


func _update_interactable() -> void:
	var nearest_interactable := _get_nearest_interactable()
	if _potential_interact and _potential_interact != nearest_interactable:
		_potential_interact.reset_highlight_colour(device_id)
	_interact_prompt.visible = false
	# TODO: Get icon dynamically?
	if nearest_interactable and nearest_interactable.can_interact(self):
		_interact_prompt.visible = true
		_potential_interact = nearest_interactable
		_potential_interact.set_highlight_colour(colour, device_id)


func _update_grabbable() -> void:
	if current_tool():
		if _potential_grab:
			_potential_grab.reset_highlight_colour(device_id)
			_potential_grab = null
			_grab_prompt.visible = false
		return
	var nearest_tool := _get_nearest_tool()
	if _potential_grab and nearest_tool != _potential_grab:
		_potential_grab.reset_highlight_colour(device_id)
	_potential_grab = nearest_tool
	# TODO: Get icon dynamically?
	_grab_prompt.visible = (_potential_grab != null)
	if _grab_prompt.visible:
		_potential_grab.set_highlight_colour(colour, device_id)
