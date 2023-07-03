extends Node2D

const PLAYER = preload("res://objects/player.tscn")
const PARTICLE = preload("res://objects/particle.tscn")

@export var particle_texture: Texture2D
@export var player_colours: Array[Color]

var _device_players: Dictionary = {}

@onready var _particles = $Particles as Node2D
@onready var _players = $Players as Node2D
@onready var _loose_tools := $LooseTools as Node2D
@onready var _menu := $Menu as CanvasLayer
@onready var _menu_colour := $Menu/ColorRect/Options/ColorRect as ColorRect
@onready var _menu_selection := $Menu/ColorRect/Options/Resume as Button
@onready var _player_spawns := $PlayerSpawns as Node2D
@onready var _klaxon := $Shipyard/Clock/Klaxon
@onready var _ship_maneuvering_zone := $Shipyard/ShipManeuveringZone as Area2D
@onready var _clock := $Shipyard/Clock as Node2D


func _ready() -> void:
	for player in $Players.get_children():
		(player as Player).accellerated.connect(_add_particle)
		_device_players[player.device_id] = player
	_resume()
	_begin()


func _add_player(device_id: int) -> void:
	var p := PLAYER.instantiate() as Player
	var i := _players.get_child_count() % player_colours.size()
	_players.add_child(p)
	p.device_id = device_id
	p.colour = player_colours[i]
	p.position = (_player_spawns.get_child(i) as Node2D).position
	p.accellerated.connect(_add_particle)
	_device_players[device_id] = p


func _add_particle(pos: Vector2, vel: Vector2, spread:= 30, colour:=Color.WHITE, lifetime:=1.0) -> void:
	var p := PARTICLE.instantiate() as ParticleSprite2D
	_particles.add_child(p)
	p.texture = particle_texture
	p.modulate = colour
	p.velocity = vel.rotated(deg_to_rad(randf_range(-spread/2.0, spread/2.0)))
	p.position = pos
	p.lifetime = lifetime


func _throw_tool(tool: Tool, _position: Vector2, velocity: Vector2) -> void:
	tool.reparent(_loose_tools)
	tool.velocity = velocity


func _begin() -> void:
	_klaxon.play()
	_ship_maneuvering_zone.visible = false
	_clock.begin()


func _time_low() -> void:
	_ship_maneuvering_zone.visible = true
	_klaxon.play()


func _timeup() -> void:
	# TODO: Check completion
	# TODO: Check for clear SMZ (Count the delay until it's clear and bill for that)
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and not _device_players.has(event.device):
		Debug.info("[Game] New Player: %d" % event.device)
		InputManager.register_gamepad(event.device)
		_add_player(event.device)
		return
	if event.is_action_pressed("toggle_menu"):
		if _menu.visible:
			_resume()
		else:
			_open_menu(_device_players[event.device])


func _open_menu(player: Player) -> void:
	_menu.visible = true
	_menu_colour.color = player.colour
	get_tree().paused = true
	_menu_selection.grab_focus()
	_menu.set_meta("player_id", player.device_id)


func _resume() -> void:
	get_tree().paused = false
	_menu.visible = false


func _remove_player() -> void:
	var id := _menu.get_meta("player_id", -1) as int
	if id >= 0:
		var player := _device_players[id] as Player
		Debug.info("[Game] Removing player %d" % player.device_id)
		player.queue_free()
		_device_players.erase(id)
		_resume()


func _settings() -> void:
	pass


func _quit() -> void:
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

