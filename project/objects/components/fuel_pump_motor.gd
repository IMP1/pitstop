class_name FuelPump
extends Interactable

signal fuel_spilled(pos, vel)

const FRAME_OFF = 0
const FRAME_ON = 1

@export var fuel_cost: float = 10
@export var fuel_per_second: float = 10
@export var ship_fuel_intake: FuelIntake
@export var nozzle_slot: Interactable
@export var nozzle: Nozzle

var spent_fuel: float = 0
var _turned_on: bool = false

@onready var _switch_on_audio := $SwitchOn as AudioStreamPlayer2D
@onready var _switch_off_audio := $SwitchOff as AudioStreamPlayer2D
@onready var _fluid_audio := $Fluid as AudioStreamPlayer2D
@onready var _switch_sprite := $SwitchSprite as Sprite2D
@onready var _highlight_line := $Highlight as Line2D


func interact(_player: Player) -> void:
	Debug.info("[Fuel Pump Motor] Pump switched")
	_turned_on = not _turned_on
	if _turned_on:
		_switch_on_audio.play()
		_fluid_audio.play()
		if not ship_fuel_intake:
			Debug.warning("[Fuel Motor] No 'Ship Fuel Intake' found")
			return
		ship_fuel_intake.show_progress = true
		_switch_sprite.frame = FRAME_ON
	else:
		_switch_off_audio.play()
		_fluid_audio.stop()
		if not ship_fuel_intake:
			Debug.warning("[Fuel Motor] No 'Ship Fuel Intake' found")
			return
		ship_fuel_intake.show_progress = false
		_switch_sprite.frame = FRAME_OFF


func _process(delta: float) -> void:
	if not _turned_on:
		return
	if not ship_fuel_intake:
		Debug.warning("[Fuel Motor] No 'Ship Fuel Intake' found")
		return
	if nozzle.get_parent() is FuelIntake:
		var remaining_capacity := ship_fuel_intake.capacity - ship_fuel_intake.fill_level
		var amount := minf(fuel_per_second * delta, remaining_capacity)
		spent_fuel += amount
		ship_fuel_intake.pump(amount)
		if amount == 0 and _fluid_audio.playing:
			Debug.info("[Fuel Motor] No more left to pump")
			_fluid_audio.stop()
		elif amount > 0 and not _fluid_audio.playing:
			_fluid_audio.play()
	elif not nozzle.get_parent() == nozzle_slot:
		spent_fuel += fuel_per_second * delta
		fuel_spilled.emit(nozzle.global_position, Vector2.ONE.rotated(nozzle.rotation + PI / 2) * 18)
		fuel_spilled.emit(nozzle.global_position, Vector2.ONE.rotated(nozzle.rotation + PI / 2) * 12)
		if not _fluid_audio.playing:
			_fluid_audio.play()
	elif nozzle.get_parent() == nozzle_slot and _fluid_audio.playing:
		_fluid_audio.stop()


func highlight(colour: Color) -> void:
	_highlight_line.default_color = colour
