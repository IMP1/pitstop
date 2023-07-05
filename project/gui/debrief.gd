class_name Debrief
extends CanvasLayer

signal confirmed

@export var negative_colour: Color = Color.DARK_RED

var _running_total: float = 0.0
var _confirmation_devices: Dictionary = {}

@onready var _tally := $Contents/Tally as VBoxContainer 
@onready var _confirmations := $Contents/Confirmation/PlayersConfirmed as HBoxContainer


func _add_item(message: String, amount: float, loss:=false) -> void:
	var hbox := HBoxContainer.new()
	_tally.add_child(hbox)
	var ref := Label.new()
	hbox.add_child(ref)
	ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ref.size_flags_horizontal += Control.SIZE_EXPAND
	ref.size_flags_stretch_ratio = 5
	ref.text = message
	
	var cost := Label.new()
	hbox.add_child(cost)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.size_flags_horizontal += Control.SIZE_EXPAND
	if loss:
		cost.add_theme_color_override("font_color", negative_colour)
		cost.text = "-£%.2f" % amount
	else:
		cost.text = "£%.2f" % amount


func add_gain(message: String, amount: float) -> void:
	_running_total += amount
	_add_item(message, amount)


func add_loss(message: String, amount: float) -> void:
	_running_total -= amount
	_add_item(message, amount, true)


func add_break() -> void:
	_tally.add_spacer(false)


func add_total(message: String = "Total") -> void:
	_add_item(message, _running_total, _running_total < 0)


func set_players_to_confirm(players: Array[Player]) -> void:
	for player in players:
		var box := ColorRect.new()
		_confirmations.add_child(box)
		box.custom_minimum_size = Vector2(12, 12)
		box.color = player.colour
		box.visible = false
		_confirmation_devices[player.device_id] = box
	Debug.info("[Debrief] %d players to confirm" % players.size())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("vote_DEVICE"):
		if not _confirmation_devices.has(event.device):
			Debug.error("[Debrief] Unrecognised device confirming: %d" % event.device)
			return
		var box := _confirmation_devices[event.device] as ColorRect
		box.visible = not box.visible
		
		var all_confirmed := true
		for confirmation in _confirmations.get_children():
			if not confirmation.visible:
				all_confirmed = false
				break
		if all_confirmed:
			Debug.info("[Debrief] All players confirmed")
			confirmed.emit()

