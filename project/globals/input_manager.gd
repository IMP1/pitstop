extends Node

signal gamepad_connected(device_id)
signal gamepad_disconnected(device_id)

enum IconTheme {
	REGULAR_COLOUR,
	SMALL_COLOUR,
	REGULAR_GREY,
	SMALL_GREY,
}

const ATLAS := preload("res://assets/icons/gdb-xbox-2 (1).png")

const INPUT_TEXTURE_RECTS_JOY_BUTTON = {
	JOY_BUTTON_A: Rect2(16, 48, 16, 16),
	JOY_BUTTON_B: Rect2(16, 80, 16, 16),
	JOY_BUTTON_X: Rect2(16, 32, 16, 16),
	JOY_BUTTON_Y: Rect2(16, 64, 16, 16),
	JOY_BUTTON_LEFT_SHOULDER: Rect2(288, 64, 16, 16),
	JOY_BUTTON_RIGHT_SHOULDER: Rect2(288, 80, 16, 16),
	JOY_BUTTON_LEFT_STICK: Rect2(184, 56, 16, 16),
	JOY_BUTTON_RIGHT_STICK: Rect2(248, 56, 16, 16),
}

const INPUT_TEXTURE_RECTS_JOY_AXIS = {
	JOY_AXIS_TRIGGER_LEFT: Rect2(288, 32, 16, 16),
	JOY_AXIS_TRIGGER_RIGHT: Rect2(288, 48, 16, 16),
	JOY_AXIS_LEFT_X: Rect2(184, 56, 16, 16),
	JOY_AXIS_LEFT_Y: Rect2(184, 56, 16, 16),
	JOY_AXIS_RIGHT_X: Rect2(248, 56, 16, 16),
	JOY_AXIS_RIGHT_Y: Rect2(248, 56, 16, 16),
}

const INPUT_TEXTURE_RECTS_KEY = {
	# TODO
}

var registered_gamepads: Dictionary = {}


func _ready():
	Input.joy_connection_changed.connect(_gamepad_connection_changed)


func register_gamepad(device_id: int):
	if registered_gamepads.has(device_id):
		Debug.info("[InputManager] Gamepad %d already registered" % device_id)
		return
	Debug.info("[InputManager] Registered gamepad %d" % device_id)
	registered_gamepads[device_id] = true
	for a in InputMap.get_actions():
		var action: String = a as String
		if action.ends_with("DEVICE"):
			var this_device_action: String = action.replace("DEVICE", str(device_id))
			Debug.info("[InputManager] Registering action '%s'" % this_device_action)
			InputMap.add_action(this_device_action)
			for e in InputMap.action_get_events(action):
				var template_event := e as InputEvent
				var device_event := template_event.duplicate() as InputEvent
				device_event.device = device_id
				InputMap.action_add_event(this_device_action, device_event)


func _gamepad_connection_changed(id: int, connected: bool) -> void:
	if connected:
		Debug.info("[InputManager] Gamepad connected: " + str(id))
		emit_signal("gamepad_connected", id)
	else:
		Debug.info("[InputManager] Gamepad disconnected: " + str(id))
		emit_signal("gamepad_disconnected", id)


func get_icon(event: InputEvent, icon_theme: IconTheme = IconTheme.REGULAR_GREY) -> Texture2D:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	var region: Rect2
	if event is InputEventJoypadButton:
		var code := (event as InputEventJoypadButton).button_index
		if INPUT_TEXTURE_RECTS_JOY_BUTTON.has(code):
			region = INPUT_TEXTURE_RECTS_JOY_BUTTON[code]
		else:
			Debug.warning("[InputManager] No region for %d" % code)
	if event is InputEventJoypadMotion:
		var code := (event as InputEventJoypadMotion).axis
		if INPUT_TEXTURE_RECTS_JOY_AXIS.has(code):
			region = INPUT_TEXTURE_RECTS_JOY_AXIS[code]
		else:
			Debug.warning("[InputManager] No region for %d" % code)
	if event is InputEventKey:
		var code := (event as InputEventKey).keycode
		if INPUT_TEXTURE_RECTS_KEY.has(code):
			region = INPUT_TEXTURE_RECTS_KEY[code]
		else:
			Debug.warning("[InputManager] No region for %d" % code)
	match icon_theme:
		IconTheme.REGULAR_GREY:
			region.position.y += 32 - 32
		IconTheme.SMALL_GREY:
			region.position.y += 160 - 32
		IconTheme.REGULAR_COLOUR:
			region.position.y += 288 - 32
		IconTheme.SMALL_COLOUR:
			region.position.y += 416 - 32
	texture.region = region
	return texture
