class_name Tool
extends CharacterBody2D

signal thrown(tool, position, velocity)

const PLAYER_COLLISION_LAYER = 1
const SHADER_COLOUR_PARAM = "color"

@export var highlight_colour: Color = Color.WHITE
@export var bounce_factor: float = 0.5

var _highlight: bool = false

@onready var _grab_shape := $GrabArea/CollisionShape2D as CollisionShape2D
@onready var _highlight_shader := $Sprite2D.material as ShaderMaterial


func grab(player: Player) -> void:
	Debug.info("[Tool] Grabbing")
	self.reparent(player._held_tools)
#	transform = player._held_tools.transform
	velocity = Vector2.ZERO
	_grab_shape.disabled = true
	set_highlight(false)


func throw(vel: Vector2) -> void:
	Debug.info("[Tool] Throwing")
	thrown.emit(self, global_position, vel)
	_grab_shape.disabled = false
	set_highlight(true)


func _physics_process(delta: float) -> void:
	if velocity == Vector2.ZERO:
		return
	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * bounce_factor


func set_highlight(val: bool) -> void:
	_highlight = val
	if _highlight:
		_highlight_shader.set_shader_parameter(SHADER_COLOUR_PARAM, highlight_colour)
	else:
		_highlight_shader.set_shader_parameter(SHADER_COLOUR_PARAM, Color(1, 1, 1, 0))
	
