extends Node

class_name Chunk

var chunkTiles = []
var center_pos: Vector2i
var world_reference: WordlMap

func _init (center : Vector2i, World : WordlMap):
	center_pos = center
	chunkTiles = World.getChunk(center)
	world_reference = World

# Convierte el chunk a JSON
func to_dict() -> Dictionary:
	var tiles_data = []
	for row in chunkTiles:
		for tile in row:
			tiles_data.append(tile.to_dict())
	
	return {
		"center_x": center_pos.x,
		"center_y": center_pos.y,
		"tiles": tiles_data
	}
