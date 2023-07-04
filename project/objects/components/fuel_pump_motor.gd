extends Interactable

signal fuel_spilled(pos, vel)

@export var fuel_per_second: float = 10
@export var ship_fuel_intake: FuelIntake
@export var nozzle_slot: Interactable
@export var nozzle: Nozzle

var _turned_on: bool = false
var _spent_fuel: float = 0

@onready var _switch_on_audio := $SwitchOn as AudioStreamPlayer2D
@onready var _switch_off_audio := $SwitchOff as AudioStreamPlayer2D
@onready var _fluid_audio := $Fluid as AudioStreamPlayer2D


func interact(_player: Player) -> void:
	Debug.info("[Fuel Pump Motor] Pump switched")
	_turned_on = not _turned_on
	if _turned_on:
		_switch_on_audio.play()
		_fluid_audio.play()
		ship_fuel_intake.show_progress = true
	else:
		_switch_off_audio.play()
		_fluid_audio.stop()
		ship_fuel_intake.show_progress = false


func _valid_nozzle_location() -> bool:
	# TODO: Where the nozzle starts (and can be returned to) is also a valid nozzle location
	return nozzle.get_parent() is FuelIntake


func _process(delta: float) -> void:
	if not _turned_on:
		return
	if nozzle.get_parent() is FuelIntake:
		var remaining_capacity := ship_fuel_intake.capacity - ship_fuel_intake.fill_level
		var amount := minf(fuel_per_second * delta, remaining_capacity)
		_spent_fuel += amount
		ship_fuel_intake.pump(amount)
		if amount == 0 and _fluid_audio.playing:
			Debug.info("[Fuel Motor] No more left to pump")
			_fluid_audio.stop()
		elif amount > 0 and not _fluid_audio.playing:
			_fluid_audio.play()
	elif not nozzle.get_parent() == nozzle_slot:
		_spent_fuel += fuel_per_second * delta
		fuel_spilled.emit(nozzle.global_position, Vector2.LEFT.rotated(nozzle.rotation) * 12)
		if not _fluid_audio.playing:
			_fluid_audio.play()
	elif nozzle.get_parent() == nozzle_slot and _fluid_audio.playing:
		_fluid_audio.stop()
