class_name UniformStation
extends Interactable

@export var game: GameScene

@onready var _highlight_line := $Highlight as Line2D


func interact(player: Player) -> void:
	assert(game.player_colours.size() == game.player_sprites.size())
	var index := game.player_colours.find(player.colour)
	index += 1
	index %= game.player_colours.size()
	player.colour = game.player_colours[index]
	player.set_sprite(game.player_sprites[index])


func highlight(colour: Color) -> void:
	_highlight_line.default_color = colour
