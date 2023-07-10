class_name GroupConfirmable
extends Control

signal confirmed

@export var post_confirmation_delay: float = 0.2

var _confirmation_devices: Dictionary = {}

@onready var _confirmations := $PlayersConfirmed as HBoxContainer


func set_players_to_confirm(players: Array[Player]) -> void:
	for player in players:
		var box := ColorRect.new()
		_confirmations.add_child(box)
		box.custom_minimum_size = Vector2(12, 12)
		box.color = player.colour
		box.visible = false
		_confirmation_devices[player.device_id] = box
	Debug.info("[Confirm] %d players to confirm" % players.size())


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"vote_DEVICE"):
		if not _confirmation_devices.has(event.device):
			Debug.error("[Confirm] Unrecognised device confirming: %d" % event.device)
			Debug.error("[Confirm] Recognised devices: %s" % str(_confirmation_devices.keys()))
			return
		var box := _confirmation_devices[event.device] as ColorRect
		box.visible = not box.visible
		
		var all_confirmed := true
		for confirmation in _confirmations.get_children():
			if not confirmation.visible:
				all_confirmed = false
				break
		if all_confirmed:
			Debug.info("[Confirm] All players confirmed")
			if post_confirmation_delay > 0:
				await get_tree().create_timer(post_confirmation_delay).timeout
			confirmed.emit()
