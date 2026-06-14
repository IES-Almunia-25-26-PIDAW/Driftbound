class_name WordlMap

#Creates an array to estore the Map in a Matrix style
var Map = []
#Counts the current Column of the matrix, gdscript does not support matrixs so its a workaround
var columnCount = -1


#Adds a new column to the matrix
func addMapColumn():
	Map.append([])
	columnCount = columnCount + 1
#Adds a tile to the map
func setMap(tile):
	Map[columnCount].append(tile)
	
func getTile(coordinate : Vector2i):
	return Map[coordinate.x][coordinate.y]
	
func getChunk(center : Vector2i):
	var chunk = []
	
	for x in range(-1,2):
		var row = []
		for y in range(-1,2):
			var pos = Vector2i(center.x + x, center.y + y)
			print(getTile(pos).coordinates)
			row.append(getTile(pos))
		chunk.append(row)
	return chunk

func Spawneable(spawnCoodinates : Vector2i, World : WordlMap):
	var spawn : WorldTile
	spawn = World.getTile(spawnCoodinates)
	
	if(spawn.tileId == Vector2i(3,0) || spawn.tileId == Vector2i(4,0)):
		return false
	else:
		return true
		
func es_centro_valido(centro: Vector2i) -> bool:
	# 1. Comprobamos los límites de la matriz dinámicamente usando el tamaño del Array
	var limite_x = Map.size()
	if limite_x == 0: return false
	var limite_y = Map[0].size()
	
	# Dejamos un margen de 1 tile para evitar desbordamientos con el cálculo del chunk (3x3)
	if centro.x < 1 or centro.x >= limite_x - 1:
		return false
	if centro.y < 1 or centro.y >= limite_y - 1:
		return false
		
	# 2. Reutilizamos tu función Spawneable para saber si es transitable (tierra/arena)
	# self se refiere a esta misma instancia de WordlMap
	return Spawneable(centro, self)
	
