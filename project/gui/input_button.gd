extends Button

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

const INPUT_TEXTURE_RECTS_JOY_BUTTON = {
	JOY_BUTTON_A: Rect2(17, 193, 14, 14),
	JOY_BUTTON_B: Rect2(17, 225, 14, 14),
	JOY_BUTTON_X: Rect2(17, 177, 14, 14),
	JOY_BUTTON_Y: Rect2(17, 209, 14, 14),
	JOY_BUTTON_LEFT_SHOULDER: Rect2(384, 87, 16, 9),
	JOY_BUTTON_RIGHT_SHOULDER: Rect2(368, 103, 16, 9),
	JOY_BUTTON_LEFT_STICK: Rect2(217, 33, 14, 14),
	JOY_BUTTON_RIGHT_STICK: Rect2(281, 33, 14, 14),
}

const INPUT_TEXTURE_RECTS_JOY_AXIS = {
	JOY_AXIS_TRIGGER_LEFT: Rect2(368, 48, 16, 16),
	JOY_AXIS_TRIGGER_RIGHT: Rect2(368, 64, 16, 16),
	JOY_AXIS_LEFT_X: Rect2(216, 72, 16, 16),
	JOY_AXIS_LEFT_Y: Rect2(216, 72, 16, 16),
	JOY_AXIS_RIGHT_X: Rect2(280, 72, 16, 16),
	JOY_AXIS_RIGHT_Y: Rect2(280, 72, 16, 16),
}

const INPUT_TEXTURE_RECTS_KEY = {
	# TODO
}

@export var action: StringName
@export var action_type: ActionType
@export var device: int


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
	if event.is_action(&"ui_up"):
		return false
	if event.is_action(&"ui_down"):
		return false
	if event.is_action(&"ui_left"):
		return false
	if event.is_action(&"ui_right"):
		return false
	# TODO: Other UI actions
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


func _get_event_in_direction(event: InputEvent, direction: JoystickDirection) -> InputEvent:
	if not event is InputEventJoypadMotion:
		return null
	var joypad_motion_event := event as InputEventJoypadMotion
	var horizontal := (direction % 2 == 0)
	if horizontal and joypad_motion_event.axis % 2 != 0:
		var horizontal_axis := int(joypad_motion_event.axis) - 1 as JoyAxis
		joypad_motion_event.axis = horizontal_axis
	elif not horizontal and joypad_motion_event.axis % 2 == 0:
		var vertical_axis := int(joypad_motion_event.axis) + 1 as JoyAxis
		joypad_motion_event.axis = vertical_axis
	return joypad_motion_event


func _remap_action(event: InputEvent):
	var action_name := action.replace("DEVICE", str(device))
	if action_name.contains("DIR"):
		for dir in JoystickDirection:
			var dir_name := (dir as String).to_lower()
			var dir_id := JoystickDirection[dir] as JoystickDirection
			var action_name_direction := action_name.replace("DIR", dir_name.to_lower())
			var event_direction := _get_event_in_direction(event, dir_id)
			InputMap.action_erase_events(action_name_direction)
			InputMap.action_add_event(action_name_direction, event_direction)
	else:
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)


func _refresh_icon(event: InputEvent):
	var region: Rect2 = (icon as AtlasTexture).region
	if event is InputEventJoypadButton:
		var code := (event as InputEventJoypadButton).button_index
		if INPUT_TEXTURE_RECTS_JOY_BUTTON.has(code):
			region = INPUT_TEXTURE_RECTS_JOY_BUTTON[code]
		else:
			Debug.warning("[InputButton] No region for %d" % code)
	if event is InputEventJoypadMotion:
		var code := (event as InputEventJoypadMotion).axis
		if INPUT_TEXTURE_RECTS_JOY_AXIS.has(code):
			region = INPUT_TEXTURE_RECTS_JOY_AXIS[code]
		else:
			Debug.warning("[InputButton] No region for %d" % code)
	if event is InputEventKey:
		var code := (event as InputEventKey).keycode
		if INPUT_TEXTURE_RECTS_KEY.has(code):
			region = INPUT_TEXTURE_RECTS_KEY[code]
		else:
			Debug.warning("[InputButton] No region for %d" % code)
	(icon as AtlasTexture).region = region

