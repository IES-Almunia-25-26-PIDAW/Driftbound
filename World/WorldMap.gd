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
	
