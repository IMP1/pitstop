class_name GameScene
extends Node2D

const PLAYER = preload("res://objects/player.tscn")
const PARTICLE = preload("res://objects/particle.tscn")

@export var particle_texture: Texture2D
@export var player_colours: Array[Color]
@export var player_sprites: Array[Texture2D]
@export_category("Shipyard Components")
@export var _patch_dispenser: PatchDispenser
@export var _ship_maneuvering_zone: ShipManeuveringZone
@export var _fuel_pump: FuelPump
@export var _clock: ShipyardClock
@export var _tool_station: ToolStation
@export var _diagnostic_display: DiagnosticDisplay
@export var _reactor_shutdown: ReactorShutdown

var _device_players: Dictionary = {}
var _job_progresses: Array[float] = []
var _is_level_over: bool = false
var _is_ship_moving: bool = false

@onready var _particles = $Particles as Node2D
@onready var _players = $Players as Node2D
@onready var _loose_tools := $LooseTools as Node2D
@onready var _menu := $Overlays/Menu as Control
@onready var _prelude := $Overlays/Prelude as Control
@onready var _prelude_confirmation := $Overlays/Prelude/GroupConfirmable as GroupConfirmable
@onready var _debrief := $Overlays/Debrief as Debrief
@onready var _game_over := $Overlays/GameOver as GameOver
@onready var _menu_colour := $Overlays/Menu/Options/ColorRect as ColorRect
@onready var _menu_selection := $Overlays/Menu/Options/Resume as Button
@onready var _menu_settings_btn := $Overlays/Menu/Options/Settings as Button
@onready var _menu_settings := $Overlays/Menu/Settings as MenuSettings
@onready var _player_spawns := $PlayerSpawns as Node2D
@onready var _ship_container := $Ship as Node2D
@onready var _klaxon := $Shipyard/Clock/Klaxon as AudioStreamPlayer2D
@onready var _countdown_timer := $Shipyard/Clock/CountdownTimer as Timer
@onready var _join_prompt := $Overlays/JoinPrompt as Control


func _ready() -> void:
	_menu.visible = false
	_debrief.visible = false
	_game_over.visible = false
	_join_prompt.visible = true
	for player in $Players.get_children():
		Debug.info("[Game] Adding player %d" % player.device_id)
		(player as Player).accellerated.connect(_add_particle)
		_device_players[player.device_id] = player
	_ship_maneuvering_zone.visible = false
	_ship_maneuvering_zone.lower_barriers()
	_reactor_shutdown.reactor_meltdown.connect(func():
		# TODO: Meltdown specific actions
		_repair_failure())
	_tool_station.release_tools.call_deferred()
	_begin()


func _add_player(device_id: int) -> void:
	_join_prompt.visible = false
	var p := PLAYER.instantiate() as Player
	var i := _players.get_child_count() % player_colours.size()
	p.device_id = device_id
	_players.add_child(p)
	await get_tree().process_frame
	p.set_colour(player_colours[i])
	p.set_sprite(player_sprites[i])
	p.position = (_player_spawns.get_child(i) as Node2D).position
	p.accellerated.connect(_add_particle)
	_device_players[p.device_id] = p
	await get_tree().process_frame
	if _prelude.visible:
		var players := [] as Array[Player]
		for player in _players.get_children():
			players.append(player as Player)
		_prelude_confirmation.set_players_to_confirm(players)


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
	Debug.info("[Game] Throwing tool %s" % tool.name)
	tool.reparent(_loose_tools)
	tool.velocity = velocity


func _setup_ship() -> void:
	var ship := _ship_container.get_child(0) as Ship
	ship.accellerated.connect(_add_particle)
	for i in ship.get_node("Components").get_child_count():
		var job := ship.get_node("Components").get_child(i) as ShipFault
		_job_progresses.append(0)
		job.progress_changed.connect(_update_repair_progress.bind(i))
	_clock.time_limit = ship.time_limit
	_fuel_pump.ship_fuel_intake = ship.get_fault(FuelIntake) as FuelIntake


func _finalise_ship() -> void:
	var ship := _ship_container.get_child(0) as Ship
	_diagnostic_display.set_ship(ship)


func _begin() -> void:
	var players := [] as Array[Player]
	for p in _players.get_children():
		players.append(p as Player)
	_prelude_confirmation.set_players_to_confirm(players)
	_prelude.visible = true
	await _prelude_confirmation.confirmed
	_prelude.visible = false
	
	_ship_maneuvering_zone.visible = true
	if not _ship_maneuvering_zone.is_clear():
		await _ship_maneuvering_zone.zone_cleared
	Debug.info("[Game] Raising barriers")
	_ship_maneuvering_zone.raise_barriers()
	
	_setup_ship()
	_countdown_timer.start()
	_clock.start_flashing()
	await _countdown_timer.timeout
	await _ship_enter()
	_clock.stop_flashing()
	_finalise_ship()
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
	_clock.stop_flashing()
	await _show_debrief()
	_ship_maneuvering_zone.visible = false
	_ship_maneuvering_zone.lower_barriers()
	_patch_dispenser.patches_created = 0 # TODO: Reset other things like this
	_setup_next_ship()


func _repair_failure() -> void:
	_is_level_over = true
	Debug.info("[Game] Mission Failure")
	_clock.stop_flashing()
	await _show_debrief()
	await _show_gameover()
	# TODO: Start again from first ship?


func _setup_next_ship() -> void:
	# TODO: Reset clock
	var old_ship := _ship_container.get_child(0)
	_ship_container.remove_child(old_ship)
	old_ship.queue_free()
	await get_tree().process_frame
	var next_ship := _determine_next_ship()
	var new_ship := (load(next_ship) as PackedScene).instantiate() as Ship
	_ship_container.add_child(new_ship)
	new_ship.position = Vector2(510, -142)
	await get_tree().process_frame
	_begin()


func _determine_next_ship() -> String:
	# TODO: Take progress into account
	return "res://ships/test_2.tscn"


func _ship_enter() -> void:
	Debug.debug("[Game] Ship entering")
	_is_ship_moving = true
	var ship := _ship_container.get_child(0) as Ship
	ship.global_position = _ship_maneuvering_zone.get_outside_position()
	Debug.info("[Game] Ship pos: " + str(ship.position))
	ship.fire_thrusters()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ship, "position", Vector2.ZERO, 6.0)
	_diagnostic_display.add_ship()
	await tween.finished
	ship.cut_thrusters()
	_countdown_timer.start()
	await _countdown_timer.timeout
	_is_ship_moving = false
	_klaxon.play()


func _ship_exit() -> void:
	Debug.info("[Game] Ship exiting")
	_klaxon.play()
	_is_ship_moving = true
	var ship := _ship_container.get_child(0) as Ship
	ship.fire_thrusters()
	_countdown_timer.start()
	await _countdown_timer.timeout
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(ship, "global_position", _ship_maneuvering_zone.get_outside_position(), 6.0)
	_diagnostic_display.remove_ship()
	await tween.finished
	ship.cut_thrusters()
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
	_debrief.result = result
	if success:
		_debrief.add_gain("Repair Job", ship.repair_reward)
		_debrief.add_break()
		
	if _patch_dispenser.patches_created > 0:
		var cost := _patch_dispenser.patches_created * _patch_dispenser.patch_price
		_debrief.add_loss("Patches x%d" % _patch_dispenser.patches_created, cost)
		pass # TODO: Get how many were unused (either children of loose-tools or a player)
		var reclaimed := 0
		if _patch_dispenser.recycled_patch_cost_reclaimed > 0 and reclaimed > 0:
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
	_debrief.confirmation.set_players_to_confirm(players)
	_debrief.visible = true
	await _debrief.confirmation.confirmed
	_debrief.visible = false


func _show_gameover() -> void:
	# TODO: Populate details of player progress (Ships completed, money accrued, etc.)
	var players := [] as Array[Player]
	for p in _players.get_children():
		players.append(p as Player)
	_game_over.confirmation.set_players_to_confirm(players)
	_game_over.visible = true
	await _game_over.confirmation.confirmed
	_game_over.visible = false


func _process(_delta: float) -> void:
	if _is_level_over:
		return
	if _is_ship_moving:
		return
	if _repair_progress() >= 1.0:
		_ship_maneuvering_zone.visible = true
		_clock.start_flashing()
		if _ship_maneuvering_zone.is_clear() and not _ship_maneuvering_zone.is_barrier_raised():
			_ship_maneuvering_zone.raise_barriers()
			_repair_success()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and not _device_players.has(event.device):
		Debug.info("[Game] New Player: %d" % event.device)
		InputManager.register_gamepad(event.device)
		_add_player(event.device)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"toggle_menu"):
		if _menu.visible:
			_resume()
		else:
			_open_menu(_device_players[event.device])
	if event.is_action_pressed(&"DEBUG_win_level"):
		Debug.info("[Game] There is no cow level")
		for i in _job_progresses.size():
			_job_progresses[i] = 1.0
	if event.is_action_pressed(&"DEBUG_lose_level"):
		Debug.info("[Game] There is, actually, a cow level")
		_clock._timelow()
		_clock._timer.start(4.0)
	if event.is_action_pressed(&"DEBUG_start_meltdown"):
		Debug.info("[Game] Reactor Meltdown!")
		_reactor_shutdown.start_meltdown()


func _open_menu(player: Player) -> void:
	# Only player opening menu can interact with it
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			for event in InputMap.action_get_events(action):
				event.device = player.device_id
	_menu.visible = true
	_menu_colour.color = player.colour
	get_tree().paused = true
	_menu_selection.grab_focus()
	_menu.set_meta("player_id", player.device_id)


func _resume() -> void:
	get_tree().paused = false
	_menu.visible = false
	# All players may interact with UI again
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			for event in InputMap.action_get_events(action):
				event.device = -1


func _remove_player() -> void:
	var id := _menu.get_meta("player_id", -1) as int
	if id >= 0:
		var player := _device_players[id] as Player
		Debug.info("[Game] Removing player %d" % player.device_id)
		player.queue_free()
		_device_players.erase(id)
		_resume()
	await get_tree().process_frame
	if _prelude.visible:
		var players := [] as Array[Player]
		for player in _players.get_children():
			players.append(player as Player)
		_prelude_confirmation.set_players_to_confirm(players)


func _settings() -> void:
	var id := _menu.get_meta("player_id", -1) as int
	_menu_settings.open(id)
	await _menu_settings.closed
	_menu_settings.visible = false
	_menu_settings_btn.grab_focus()


func _quit() -> void:
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
