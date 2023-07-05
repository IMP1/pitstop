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
@onready var _debrief := $Debrief as Debrief
@onready var _menu_colour := $Menu/Options/ColorRect as ColorRect
@onready var _menu_selection := $Menu/Options/Resume as Button
@onready var _player_spawns := $PlayerSpawns as Node2D
@onready var _ship_container := $Ship as Node2D
@onready var _klaxon := $Shipyard/Clock/Klaxon as AudioStreamPlayer2D
@onready var _countdown_timer := $Shipyard/Clock/CountdownTimer as Timer

# Shipyard Components
@onready var _patch_dispenser := $Shipyard/PatchDispenser as PatchDispenser
@onready var _ship_maneuvering_zone := $Shipyard/ShipManeuveringZone as ShipManeuveringZone
@onready var _fuel_pump := $Shipyard/FuelPump/PumpSwitch as FuelPump
@onready var _clock := $Shipyard/Clock as ShipyardClock


func _ready() -> void:
	_menu.visible = false
	_debrief.visible = false
	for player in $Players.get_children():
		(player as Player).accellerated.connect(_add_particle)
		_device_players[player.device_id] = player
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


func _add_tool(tool: Tool) -> void:
	tool.thrown.connect(_throw_tool)


func _throw_tool(tool: Tool, _position: Vector2, velocity: Vector2) -> void:
	tool.reparent(_loose_tools)
	tool.velocity = velocity


func _setup_ship() -> void:
	var ship := _ship_container.get_child(0) as Ship
	for i in ship.get_node("Components").get_child_count():
		var job := ship.get_node("Components").get_child(i) as ShipFault
		_job_progresses.append(0)
		job.progress_changed.connect(_update_repair_progress.bind(i))
	_clock.time_limit = ship.time_limit


func _begin() -> void:
	_countdown_timer.start()
	await _countdown_timer.timeout
	await _ship_enter()
	_setup_ship()
	_ship_maneuvering_zone.visible = false
	_ship_maneuvering_zone.lower_barriers()
	_clock.begin()


func _time_low() -> void:
	_klaxon.play()
	# TODO: Turn time red? # Intensify music!


func _repair_success() -> void:
	_clock.stop()
	_is_level_over = true
	Debug.info("[Game] Mission Success!")
	await _ship_exit()
	await _show_debrief()
	# TODO: End the level


func _repair_failure() -> void:
	_is_level_over = true
	Debug.info("[Game] Mission Failure")
	_ship_exit()
	await _show_debrief()
	# TODO: End the level


func _ship_enter() -> void:
	Debug.debug("[Game] Ship entering")
	_is_ship_moving = true
	var ship := _ship_container.get_child(0) as Ship
	ship.global_position = _ship_maneuvering_zone.get_outside_position()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ship, "position", Vector2.ZERO, 2.0)
	# TODO: Set ease
	await tween.finished
	# TODO: Have some animation? A clamping thing?
	_countdown_timer.start()
	await _countdown_timer.timeout
	_is_ship_moving = false
	_klaxon.play()


func _ship_exit() -> void:
	Debug.info("[Game] Ship exiting")
	_klaxon.play()
	_is_ship_moving = true
	# TODO: Have some animation? An unclamping thing?
	_countdown_timer.start()
	await _countdown_timer.timeout
	var ship := _ship_container.get_child(0) as Ship
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(ship, "global_position", _ship_maneuvering_zone.get_outside_position(), 2.0)
	# TODO: Set ease
	await tween.finished
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


func _show_debrief() -> void:
	var ship := $Ship.get_child(0) as Ship
	var success := _repair_progress() >= 1.0
	var result := "Success" if success else "Failure"
	if success:
		_debrief.add_gain("Repair Job", ship.repair_reward)
		_debrief.add_break()
		
	if _patch_dispenser.patches_created > 0:
		var cost := _patch_dispenser.patches_created * _patch_dispenser.patch_price
		_debrief.add_loss("Patches x%d" % _patch_dispenser.patches_created, cost)
		if _patch_dispenser.recycled_patch_cost_reclaimed > 0:
			pass # TODO: Get how many were unused (either children of loose-tools or a player)
			var reclaimed := 0
			var recouped := reclaimed * _patch_dispenser.recycled_patch_cost_reclaimed
			_debrief.add_gain("Patches Recycled x%d" % reclaimed, recouped)
	
	if _fuel_pump.spent_fuel > 0:
		var cost := _fuel_pump.spent_fuel * _fuel_pump.fuel_cost
		_debrief.add_loss("Fuel", cost)
	
	var time_left := _clock.time_left()
	if time_left > 0:
		var bonus := time_left * ship.early_bonus
		_debrief.add_gain("Finished Early", bonus)
	
	_debrief.add_break()
	_debrief.add_total()
	
	var players := [] as Array[Player]
	for p in _players.get_children():
		players.append(p as Player)
	_debrief.set_players_to_confirm(players)
	_debrief.visible = true
	
	await _debrief.confirmed


func _process(_delta: float) -> void:
	if _is_level_over:
		return
	if _is_ship_moving:
		return
	if _repair_progress() >= 1.0:
		_ship_maneuvering_zone.visible = true
		if _is_smz_clear() and not _ship_maneuvering_zone.is_barrier_raised():
			_ship_maneuvering_zone.raise_barriers()
			_repair_success()


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
		Debug.info("[Game] There is no cow level")
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

