class_name Ship
extends CharacterBody2D

const THRUSTERS_FIRING = &"firing"
const THRUSTERS_STOPPED = &"default"

@export var repair_reward: float = 100
@export var time_limit: float = 60
@export var early_bonus: float = 25

@onready var _thrusters := $Thrusters as AnimatedSprite2D


func fire_thrusters() -> void:
	_thrusters.play(THRUSTERS_FIRING)


func cut_thrusters() -> void:
	_thrusters.play(THRUSTERS_STOPPED)

