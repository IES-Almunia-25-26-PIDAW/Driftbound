extends TileMap
var jugador = preload("res://player/Player.tscn").instantiate()
const ENEMY_SCENE = preload("res://Enemigos/Enemy.tscn")

@export var min_spawn_distance: float = 200.0 # Distancia mínima para que no aparezca encima
@export var max_spawn_distance: float = 400.0 # Distancia máxima para que no aparezca fuera de pantalla
@export var tiempo_entre_spawns: float = 3.0 # Segundos entre cada enemigo

var chunk_data : Chunk
signal creandoChunk() 
var spawn_timer: Timer
var Player : CharacterBody2D

var posicion_spawn_jugador

func _ready() -> void:
	
	# --- CONFIGURACIÓN DEL TIMER POR CÓDIGO ---
	
	# 1. Creamos la instancia del nodo Timer
	spawn_timer = Timer.new()
	
	# 2. Configuramos sus propiedades
	spawn_timer.wait_time = tiempo_entre_spawns  # Tiempo en segundos
	spawn_timer.one_shot = false                 # false significa que es un bucle infinito
	spawn_timer.autostart = true                 # Se activa solo al entrar a la escena
	
	# 3. Conectamos la señal "timeout" a nuestra función de spawn
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# 4. Añadimos el Timer como hijo de este nodo para que empiece a funcionar
	add_child(spawn_timer)

func dibujar_tiles():
	var escala = 100
	
	for x in range(chunk_data.chunkTiles.size()):
		for y in range(chunk_data.chunkTiles[x].size()):
			
			var tile = chunk_data.chunkTiles[x][y]
			
			for i in range(escala):
				for j in range(escala):
					
					var pos = Vector2i(x * escala + i, y * escala + j)
					
					if(tile.tileId == Vector2i(0,0)):
						set_cell(0, pos, 1, Vector2i(5,22), 0)
					if(tile.tileId == Vector2i(1,0)):
						set_cell(0, pos, 0, Vector2i(2,2), 0)
					if(tile.tileId == Vector2i(2,0)):
						set_cell(0, pos, 1, Vector2i(6,10), 0)
					if(tile.tileId == Vector2i(3,0)):
						set_cell(0, pos, 0, Vector2i(2,7), 0)
					if(tile.tileId == Vector2i(4,0)):
						set_cell(0, pos, 0, Vector2i(2,7), 0)
						
func calcular_punto_spawn_tierra():
	# 1. Extraemos todas las casillas que son tierra en una sola línea limpia
	var tierras = chunk_data.chunkTiles.duplicate() # Evitamos alterar la matriz original
	var casillas = []
	for row in tierras: casillas.append_array(row.filter(func(tile): return tile.tileId.x in [0, 1, 2]))
	
	if casillas.is_empty(): return
	
	# 2. Elegimos una casilla lógica al azar
	var casilla_elegida = casillas[randi() % casillas.size()].coordinates
	
	# 3. Calculamos la posición real escalada (100) con el offset aleatorio centrado
	posicion_spawn_jugador = map_to_local(casilla_elegida + Vector2i(randi_range(35, 65), randi_range(35, 65)))
	print(posicion_spawn_jugador)
						
func spawnear_jugador():
	if jugador:
		add_child(jugador)
		Player = jugador.get_child(0)
		calcular_punto_spawn_tierra()
		jugador.global_position = posicion_spawn_jugador
		
		# 2. Creamos la cámara por código
		var camera = Camera2D.new()
		
		# 3. Configuramos las propiedades de la cámara
		camera.enabled = true
		camera.position = Vector2.ZERO # (0,0) para que se centre exactamente en el jugador
		
		# Opcional: Activamos el suavizado para que el movimiento sea fluido
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 6.0 # Velocidad del suavizado
		
		# 4. ¡EL TRUCO CRÍTICO!: Añadimos la cámara como HIJA del jugador
		jugador.add_child(camera)
		
func _on_spawn_timer_timeout() -> void:
	# Cada vez que el temporizador llegue a 0, ejecutamos el spawn
	spawn_enemigo_cerca()
		
func spawn_enemigo_cerca():
	if not jugador: 
		print("No se encontró al jugador para spawnear al enemigo.")
		return
		
	# 1. Instanciamos el enemigo
	var nuevo_enemigo = ENEMY_SCENE.instantiate()
	
	# 2. CALCULAMOS LA POSICIÓN ALEATORIA EN UN ANILLO
	var angulo_aleatorio = randf_range(0, 2 * PI) # Ángulo al azar en radianes (0 a 360°)
	var distancia_aleatoria = randf_range(min_spawn_distance, max_spawn_distance)
	
	# Convertimos el ángulo y la distancia en un vector de dirección
	var vector_direccion = Vector2(cos(angulo_aleatorio), sin(angulo_aleatorio))
	var offset_posicion = vector_direccion * distancia_aleatoria
	
	# 3. Posicionamos al enemigo sumando el offset a la posición del jugador
	nuevo_enemigo.global_position = Player.global_position + offset_posicion
	
	# 4. Añadimos el enemigo al mapa
	add_child(nuevo_enemigo)

func get_player_pos() -> Vector2:
	if Player:
		return Player.global_position
	return Vector2.ZERO
		

func setup(_chunk_data):
	chunk_data = _chunk_data
	emit_signal("creandoChunk")
	dibujar_tiles()
	spawnear_jugador()
