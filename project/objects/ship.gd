class_name Ship
extends CharacterBody2D

const THRUSTERS_FIRING = &"firing"
const THRUSTERS_STOPPED = &"default"

@export var repair_reward: float = 100
@export var time_limit: float = 60
@export var early_bonus: float = 25

@onready var _thrusters := $Thrusters as AnimatedSprite2D
@onready var _components := $Components as Node2D


func fire_thrusters() -> void:
	_thrusters.play(THRUSTERS_FIRING)


func cut_thrusters() -> void:
	_thrusters.play(THRUSTERS_STOPPED)


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

