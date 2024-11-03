extends Button
class_name InputMappingButton

signal action_remapped(device: int, action_name: StringName, event: InputEvent)

enum ActionType {
	BUTTON,
	AXIS
}

enum JoystickDirection {
	UP,
	LEFT,
	DOWN,
	RIGHT,
}

const EPSILON := 0.4

@export var action: StringName
@export var action_type: ActionType
@export var device: int
@export var ignored_actions: Array[StringName] = [
	&"ui_up",
	&"ui_down",
	&"ui_left",
	&"ui_right",
	# TODO: Other UI actions
]


func _ready() -> void:
	var action_name = action.replace("DIR", "up")
	if not InputMap.has_action(action_name):
		Debug.error("[InputButton] Unrecognised action: '%s'" % action_name)
		return
	if InputMap.action_get_events(action_name).is_empty():
		Debug.error("[InputButton] Action has no events")
		return
	var event: InputEvent = InputMap.action_get_events(action_name)[0]
	_refresh_icon(event)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not has_focus():
		return
	if _is_valid_input_for_action(event):
		_remap_action(event)
		_refresh_icon(event)


func _is_valid_input_for_action(event: InputEvent) -> bool:
	if ignored_actions.any(func(action_to_ignore: StringName) -> bool: return event.is_action(action_to_ignore)):
		return false
	if event.device != device:
		return false
	match action_type:
		ActionType.BUTTON:
			var is_button := false
			if event is InputEventMouseButton: is_button = true
			if event is InputEventKey: is_button = true
			if event is InputEventJoypadButton: is_button = true
			if event is InputEventJoypadMotion:
				if (event as InputEventJoypadMotion).axis == JOY_AXIS_TRIGGER_LEFT:
					is_button = true
				if (event as InputEventJoypadMotion).axis == JOY_AXIS_TRIGGER_RIGHT:
					is_button = true
			if not is_button:
				return false
			if event is InputEventMouseButton and not (event as InputEventMouseButton).pressed:
				return false
			if event is InputEventKey and not (event as InputEventKey).pressed:
				return false
			if event is InputEventJoypadButton and not (event as InputEventJoypadButton).pressed:
				return false
		ActionType.AXIS:
			if not (event is InputEventJoypadMotion):
				return false
			if absf((event as InputEventJoypadMotion).axis_value) < EPSILON:
				return false
	return true


@warning_ignore("int_as_enum_without_cast")
func _get_event_in_direction(event: InputEvent, direction: JoystickDirection) -> InputEvent:
	if not event is InputEventJoypadMotion:
		Debug.error("[InputButton] Input is not a Joypad Motion Event")
		return null
	var joypad_motion_event := event as InputEventJoypadMotion
	var new_event := InputEventJoypadMotion.new()
	new_event.device = device
	# SEE: https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html#enum-globalscope-joyaxis
	new_event.axis = joypad_motion_event.axis
	match direction:
		JoystickDirection.UP:
			if joypad_motion_event.axis % 2 == 0:
				new_event.axis += 1
			new_event.axis_value = -1
		JoystickDirection.DOWN:
			if joypad_motion_event.axis % 2 == 0:
				new_event.axis += 1
			new_event.axis_value = 1
		JoystickDirection.LEFT:
			if joypad_motion_event.axis % 2 == 1:
				new_event.axis -= 1
			new_event.axis_value = -1
		JoystickDirection.RIGHT:
			if joypad_motion_event.axis % 2 == 1:
				new_event.axis -= 1
			new_event.axis_value = 1
	return new_event


func _remap_action(event: InputEvent):
	var action_name := action.replace("DEVICE", str(device))
	if action_name.contains("DIR"):
		for dir in JoystickDirection:
			var dir_name := str(dir).to_lower()
			var dir_id := JoystickDirection[dir] as JoystickDirection
			var directional_action_name := action_name.replace("DIR", dir_name.to_lower())
			var directional_event := _get_event_in_direction(event, dir_id)
			InputMap.action_erase_events(directional_action_name)
			InputMap.action_add_event(directional_action_name, directional_event)
			Debug.info("[InputButton] Remapped action '%s'" % directional_action_name)
			Debug.info("              %s" % str(directional_event))
			action_remapped.emit(device, directional_action_name, directional_event)
	else:
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)
		Debug.info("[InputButton] Remapped action '%s'" % action_name)
		Debug.info("              %s" % str(event))
		action_remapped.emit(device, action_name, event)


func _refresh_icon(event: InputEvent):
	icon = InputManager.get_icon(event)
