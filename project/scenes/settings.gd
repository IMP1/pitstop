extends Control
class_name MenuSettings

signal closed

const AUDIO_BUS_MASTER := 0
const AUDIO_BUS_MUSIC := 1
const AUDIO_BUS_SOUNDS := 2

@onready var _tab_select := $HSelect as HSelect
@onready var _tab_container := $TabContainer as TabContainer
@onready var _audio_volume_master := $TabContainer/Audio/VolumeList/Master/HSlider as HSlider
@onready var _audio_volume_music := $TabContainer/Audio/VolumeList/Music/HSlider as HSlider
@onready var _audio_volume_sounds := $TabContainer/Audio/VolumeList/Sounds/HSlider as HSlider
@onready var _controls_list := $TabContainer/Controls/ScrollContainer/InputList as Control


func _ready() -> void:
	_audio_volume_master.value_changed.connect(func(value: float):
		AudioServer.set_bus_volume_db(AUDIO_BUS_MASTER, linear_to_db(value)))
	_audio_volume_music.value_changed.connect(func(value: float):
		AudioServer.set_bus_volume_db(AUDIO_BUS_MUSIC, linear_to_db(value)))
	_audio_volume_sounds.value_changed.connect(func(value: float):
		AudioServer.set_bus_volume_db(AUDIO_BUS_SOUNDS, linear_to_db(value)))


func _set_settings_tab() -> void:
	_tab_container.current_tab = _tab_select.selected_index


func open(device_id: int) -> void:
	_setup(device_id)
	visible = true
	_tab_select.grab_focus()


func _close() -> void:
	closed.emit()


func _setup(device_id: int) -> void:
	for list_item in _controls_list.get_children():
		if not list_item is HBoxContainer: 
			continue
		var btn := list_item.get_node(^"InputButton") as InputMappingButton
		btn.device = device_id
	# NOTE: InputButtons are handling remapping inputs themselves
	_audio_volume_master.value = db_to_linear(AudioServer.get_bus_volume_db(AUDIO_BUS_MASTER))
	_audio_volume_music.value = db_to_linear(AudioServer.get_bus_volume_db(AUDIO_BUS_MUSIC))
	_audio_volume_sounds.value = db_to_linear(AudioServer.get_bus_volume_db(AUDIO_BUS_SOUNDS))
