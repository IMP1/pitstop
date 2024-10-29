class_name Interactable
extends Node2D

@export var hold_to_interact: bool = false
@export var highlight_colour: Color = Color.WHITE
@export var multiple_highlight_colour: Color = Color.WHITE

var _device_interacting: int
var _highlight: bool = true
var _players_highlighting: Dictionary = {}

@warning_ignore("unused_private_class_variable")
@onready var _area := $Area2D as Area2D


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


func _player_left(body: Node2D) -> void:
	if not body is Player:
		return
	var player := body as Player
	if player.device_id == _device_interacting:
		Debug.debug("[Interactable] Player has left the interactable area.")
		stop_interacting()


func set_highlight(val: bool) -> void:
	_highlight = val
	if _highlight:
		highlight(highlight_colour)
	else:
		highlight(Color(1, 1, 1, 0))


func set_highlight_colour(colour: Color, id: int) -> void:
	_players_highlighting[id] = true
	if _players_highlighting.size() > 1:
		highlight_colour = multiple_highlight_colour
	else:
		highlight_colour = colour
	if _highlight:
		highlight(highlight_colour)


func reset_highlight_colour(id: int) -> void:
	_players_highlighting.erase(id)
	if _players_highlighting.size() == 0:
		highlight_colour = Color.WHITE
	if _highlight:
		highlight(highlight_colour)


func highlight(_color: Color) -> void:
	# To be overwritten
	pass # TODO: Highlight somehow
