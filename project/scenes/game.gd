extends Node2D

const PLAYER = preload("res://objects/player.tscn")
const PARTICLE = preload("res://objects/particle.tscn")

@export var particle_texture: Texture2D
@export var player_colours: Array[Color]

var _device_players: Dictionary = {}
var _job_progresses: Array[float] = []
var _is_level_over: bool = false
var _is_ship_moving: bool = false

@onready var _particles = $Particles as Node2D
@onready var _players = $Players as Node2D
@onready var _loose_tools := $LooseTools as Node2D
@onready var _menu := $Menu as CanvasLayer
@onready var _menu_colour := $Menu/ColorRect/Options/ColorRect as ColorRect
@onready var _menu_selection := $Menu/ColorRect/Options/Resume as Button
@onready var _player_spawns := $PlayerSpawns as Node2D
@onready var _klaxon := $Shipyard/Clock/Klaxon as AudioStreamPlayer2D
@onready var _ship_maneuvering_zone := $Shipyard/ShipManeuveringZone as Area2D
@onready var _smz_barriers := $Shipyard/ShipManeuveringZone/Barriers/CollisionShape2D as CollisionShape2D
@onready var _clock := $Shipyard/Clock as ShipyardClock
@onready var _ship_container := $Ship


func _ready() -> void:
	_menu.visible = false
	for player in $Players.get_children():
		(player as Player).accellerated.connect(_add_particle)
		_device_players[player.device_id] = player
	_begin()
	for job in _ship_container.get_child(0).get_node("Components").get_children():
		_job_progresses.append(0)


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


func _add_tool(tool: Tool) -> void:
	tool.thrown.connect(_throw_tool)


func _throw_tool(tool: Tool, _position: Vector2, velocity: Vector2) -> void:
	tool.reparent(_loose_tools)
	tool.velocity = velocity


func _begin() -> void:
	await _ship_enter()
	_klaxon.play()
	_ship_maneuvering_zone.visible = false
	_smz_barriers.disabled = true
	_clock.begin()


func _time_low() -> void:
	_klaxon.play()
	# TODO: Turn time red? # Intensify music!


func _repair_success() -> void:
	_clock.stop()
	_is_level_over = true
	Debug.info("[Game] Mission Success!")
	_ship_exit()
	# TODO: Show a debrief and losses/gains


func _repair_failure() -> void:
	_is_level_over = true
	Debug.info("[Game] Mission Failure")
	# YOU LOSE! It's harsh, but I think better than just waiting for you to complete
	# TODO: Show a debrief and losses/gains


func _ship_enter() -> void:
	Debug.info("[Game] Ship entering")
	_is_ship_moving = true
	await get_tree().create_timer(1.0).timeout
	# TODO: Bring in the ship
	_is_ship_moving = false


func _ship_exit() -> void:
	Debug.info("[Game] Ship exiting")
	_is_ship_moving = true
	await get_tree().create_timer(1.0).timeout
	# TODO: Send out the ship
	_is_ship_moving = false


func _update_repair_progress(value: float, job: int) -> void:
	_job_progresses[job] = value
	if value >= 1.0:
		Debug.info("[Game] Job %d finished" % job)


func _repair_progress() -> float:
	var total := 0.0
	for n in _job_progresses:
		total += n
	total /= _job_progresses.size()
	return total


func _is_smz_clear() -> bool:
	return not _ship_maneuvering_zone.has_overlapping_bodies()


func _process(_delta: float) -> void:
	if _is_level_over:
		return
	if _is_ship_moving:
		return
	if _repair_progress() >= 1.0:
		if _is_smz_clear() and _smz_barriers.disabled:
			_smz_barriers.disabled = false
			_repair_success()
		elif not _ship_maneuvering_zone.visible:
			_ship_maneuvering_zone.visible = true


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
	if event.is_action_pressed("DEBUG_win_level"):
		for i in _job_progresses.size():
			_job_progresses[i] = 1.0


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

