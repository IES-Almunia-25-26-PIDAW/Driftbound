class_name WorldTile

var tileId: Vector2i
var coordinates : Vector2i

#This constructor should recieve 1 vector2i variable
#The vector2i is the 
#The type variable is the type of the tileº
func _init(_tileId: Vector2i, _coordinates: Vector2i):
	tileId = _tileId
	coordinates = _coordinates
	
# Convierte el objeto a un diccionario apto para JSON
func to_dict() -> Dictionary:
	return {
		"tile_id_x": tileId.x,
		"tile_id_y": tileId.y,
		"pos_x": coordinates.x,
		"pos_y": coordinates.y
	}

# Reconstruye el objeto desde un diccionario
static func from_dict(data: Dictionary) -> WorldTile:
	var t_id = Vector2i(data["tile_id_x"], data["tile_id_y"])
	var coords = Vector2i(data["pos_x"], data["pos_y"])
	return WorldTile.new(t_id, coords)
