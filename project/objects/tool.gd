class_name Tool
extends BounceBody2D

signal thrown(tool, position, velocity)

const PLAYER_COLLISION_LAYER = 1
const SHADER_COLOUR_PARAM = "color"

@export var highlight_colour: Color = Color.WHITE
@export var multiple_highlight_colour: Color = Color.WHITE
@export var bounce_factor: float = 0.5

var _highlight: bool = false
var _players_highlighting: Dictionary = {}

@onready var _grab_shape := $GrabArea/CollisionShape2D as CollisionShape2D
@onready var _highlight_shader := $Sprite2D.material as ShaderMaterial
@onready var _shadow := $Sprite2D/Shadow as Sprite2D
@onready var _sprite := $Sprite2D as Sprite2D


func _ready() -> void:
	_shadow.texture = _sprite.texture


func grab(player: Player) -> void:
	Debug.info("[Tool] Grabbing")
	self.reparent(player._held_tools)
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
		Debug.debug("[Tool] Colliding" + str(collision.get_collider().name))
		_collide(collision)


func set_highlight(val: bool) -> void:
	_highlight = val
	if _highlight:
		_highlight_shader.set_shader_parameter(SHADER_COLOUR_PARAM, highlight_colour)
	else:
		_highlight_shader.set_shader_parameter(SHADER_COLOUR_PARAM, Color(1, 1, 1, 0))


func set_highlight_colour(colour: Color, id: int) -> void:
	_players_highlighting[id] = true
	if _players_highlighting.size() > 1:
		highlight_colour = multiple_highlight_colour
	else:
		highlight_colour = colour
	if _highlight:
		_highlight_shader.set_shader_parameter(SHADER_COLOUR_PARAM, highlight_colour)


func reset_highlight_colour(id: int) -> void:
	_players_highlighting.erase(id)
	if _players_highlighting.size() == 0:
		highlight_colour = Color.WHITE
	if _highlight:
		_highlight_shader.set_shader_parameter(SHADER_COLOUR_PARAM, highlight_colour)

