extends Node

signal gamepad_connected(device_id)
signal gamepad_disconnected(device_id)

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
			Debug.info("[InputManager] Registering action '%s' for device %d" % [action, device_id])
			var this_device_action: String = action.replace("DEVICE", str(device_id))
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



