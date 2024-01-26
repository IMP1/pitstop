class_name Ship
extends CharacterBody2D

signal accellerated(position: Vector2, velocity: Vector2, spread: float, colour: Color)

const PROPULSION_PARTICLE_SPEED = 16

@export var repair_reward: float = 100
@export var time_limit: float = 60
@export var early_bonus: float = 25

var _is_accellerating := false
var _last_position: Vector2

@onready var _collision := $CollisionPolygon2D as CollisionPolygon2D
@onready var _thrusters := $Thrusters as Node2D
@onready var _components := $Components as Node2D


func fire_thrusters() -> void:
	_is_accellerating = true
	_last_position = global_position


func cut_thrusters() -> void:
	_is_accellerating = false


func _process(_delta: float) -> void:
	if not _is_accellerating:
		return
	var movement := (global_position - _last_position) / _delta
	var spread: float = 30.0
	if movement.length_squared() > 1:
		spread /= 3
	for thruster in _thrusters.get_children():
		var thruster_pos = (thruster as Node2D).position
		var accelleration = movement + Vector2.LEFT * PROPULSION_PARTICLE_SPEED
		accellerated.emit(global_position + thruster_pos, accelleration, spread, Color.WHITE)
	_last_position = global_position


func get_fault(fault_type) -> ShipFault:
	for comp in _components.get_children():
		if comp is ShipFault:
			if is_instance_of(comp, fault_type):
				return comp as ShipFault
	return null


func get_faults() -> Array[ShipFault]:
	var list := [] as Array[ShipFault]
	for comp in _components.get_children():
		if comp is ShipFault:
			list.append(comp)
	return list

