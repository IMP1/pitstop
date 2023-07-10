class_name UniformStation
extends Interactable

@export var game: GameScene


func interact(player: Player) -> void:
	assert(game.player_colours.size() == game.player_sprites.size())
	Debug.info("[Uniform Station] Cycling player %d's uniform" % player.device_id)
	var index := game.player_colours.find(player.colour)
	index += 1
	index %= game.player_colours.size()
	player.colour = game.player_colours[index]
	player.set_sprite(game.player_sprites[index])
	Debug.info("[Uniform Station] Currently %d")