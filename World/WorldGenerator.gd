extends TileMap

var World := WordlMap.new()

var map_width : int = 90
var map_height : int = 90
var fallof
var type
var spawn_creado = false

var rng := RandomNumberGenerator.new()

var noise := FastNoiseLite.new()

var worldMap = {}

var spawn_point_x
var spawn_point_y
var spawn_point
var WorldAndSpawnPoint = []

signal world_ready(map_width, map_height)
signal SetSpawnPoint()
signal SpawnPointCreado()



var chunk_scene = preload("res://ChunkScene/ChunkScene.tscn")
var SaveManager = preload("res://GestorGuardado/GestorGuardao.tscn").instantiate()


func _ready():

	rng.randomize()
	
	# Intentar cargar mapa existente
	var mapa_guardado = SaveManager.load_world_map()
	
	if mapa_guardado != null:
		World = mapa_guardado
		print("¡Mapa cargado desde el archivo JSON!")
		set_spawn_point()
		
	else:
		print("No hay partida guardada. Generando nuevo mundo...")
		setup_noise()
		WorldAndSpawnPoint = generate_world()
		# Guardar el mapa base recién generado
		SaveManager.save_world_map(World)

#func _process(delta):
	#if Input.is_action_pressed("enter"):
		#var chunk_data = Chunk.new(spawn_point, World)
		#print(chunk_data)
		#var scene = chunk_scene.instantiate()
		#scene.get_node("TileMap").setup(chunk_data)
		#get_tree().current_scene.add_child(scene)

func setup_noise():
	
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# controla el tamaño de las formas
	noise.frequency = 0.02

	# añade detalle
	noise.fractal_octaves = 2
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0


func generate_world():

	for x in range(map_width):
		World.addMapColumn()
		for y in range(map_height):
			worldMap[[x,y]] = noise.get_noise_2d(x, y)
			var height = worldMap[[x,y]]
			draw_tile(x, y, height)
	set_spawn_point()
	return [World, spawn_point]
	


func draw_tile(x, y, height):

	var tile_id
	
	if (x <= 1) or (y <= 1)  or ( x > map_width - 3) or (y > map_height - 3):
		tile_id = Vector2i(3,0)   # agua
	else:	
		if height < -0.2:
			tile_id = Vector2i(4,0)   # agua profunda

		elif height < 0:
			tile_id = Vector2i(3,0)   # agua

		elif height < 0.2:
			tile_id = Vector2i(2,0)   # arena

		elif height < 0.5:
			tile_id = Vector2i(1,0)   # hierba
				
		elif height >= 0.5:
			tile_id = Vector2i(0,0)
			
	set_cell(0, Vector2i(x,y), 0, tile_id, 0)
	World.setMap(WorldTile.new(tile_id, Vector2i(x,y)))



func set_spawn_point() -> void:
	while true:
		spawn_point_x = rng.randi_range(0, 29)*3 + 1
		spawn_point_y = rng.randi_range(0, 29)*3 + 1
		spawn_point = Vector2i(spawn_point_x, spawn_point_y)
		if(World.Spawneable(spawn_point, World)):
			print(World.getTile(spawn_point).tileId)
			spawn_creado = true
			break
			
func getWorldAndSpawnPoint():
	return WorldAndSpawnPoint
	
func getSpawnPoint():
	return spawn_point
