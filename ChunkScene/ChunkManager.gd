extends TileMap
var jugador = preload("res://player/Player.tscn").instantiate()
const ENEMY_SCENE = preload("res://Enemigos/Enemy.tscn")
const COFRE_NORMAL = preload("res://Cofre/cofre.tscn")
const COFRE_MIMIC = preload("res://Cofre/Mimic/mimic.tscn")

@export var min_spawn_distance: float = 200.0 # Distancia mínima para que no aparezca encima
@export var max_spawn_distance: float = 400.0 # Distancia máxima para que no aparezca fuera de pantalla
@export var tiempo_entre_spawns: float = 3.0 # Segundos entre cada enemigo

var chunk_data : Chunk
signal creandoChunk() 
var spawn_timer: Timer
var Player : CharacterBody2D

var posicion_spawn_jugador

signal cambiar_de_chunk(direccion: Vector2i)

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
	
func setup(_chunk_data, vector_entrada, es_posicion_directa: bool = false):
	chunk_data = _chunk_data
	emit_signal("creandoChunk")
	dibujar_tiles()
	
	# Le pasamos el flag al método de spawneo
	spawnear_jugador(vector_entrada, es_posicion_directa)
	Global.Player = Player
	generar_limites_colision()
	
	Global.chunk_actual = chunk_data
	
	# 🌟 ACTUALIZACIÓN AUTOMÁTICA EN MEMORIA Y LLAMADA AL AUTO-GUARDADO
	Global.actualizar_datos_guardado(chunk_data.center_pos, get_player_pos())
	Global.solicitar_guardado()

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
						
func generar_limites_colision():
	# 1. Calculamos el tamaño real del mapa en píxeles
	var tamaño_celda_pixel = tile_set.tile_size.x
	var ancho_total = 3 * 100 * tamaño_celda_pixel # 3 casillas de chunk * 100 de escala
	var alto_total = 3 * 100 * tamaño_celda_pixel
	var grosor_borde = 20.0 # El ancho de la zona que activa el cambio
	
	# Configuración de los 4 bordes: [Dirección lógica, Posición Central, Tamaño de la Caja]
	var bordes = [
		{
			"dir": Vector2i(0, -1), # ARRIBA
			"pos": Vector2(ancho_total / 2.0, -grosor_borde / 2.0),
			"size": Vector2(ancho_total, grosor_borde)
		},
		{
			"dir": Vector2i(0, 1),  # ABAJO
			"pos": Vector2(ancho_total / 2.0, alto_total + (grosor_borde / 2.0)),
			"size": Vector2(ancho_total, grosor_borde)
		},
		{
			"dir": Vector2i(-1, 0), # IZQUIERDA
			"pos": Vector2(-grosor_borde / 2.0, alto_total / 2.0),
			"size": Vector2(grosor_borde, alto_total)
		},
		{
			"dir": Vector2i(1, 0),  # DERECHA
			"pos": Vector2(ancho_total + (grosor_borde / 2.0), alto_total / 2.0),
			"size": Vector2(grosor_borde, alto_total)
		}
	]
	
	# 2. Creamos los nodos físicamente
	for datos in bordes:
		var area = Area2D.new()
		var collision = CollisionShape2D.new()
		var box = RectangleShape2D.new()
		
		box.size = datos["size"]
		collision.shape = box
		area.position = datos["pos"]
		
		area.add_child(collision)
		add_child(area)
		
		# Configuramos las máscaras para que SOLO detecte al jugador (Capa 1 por defecto)
		area.collision_layer = 0 
		area.collision_mask = 256
		
		# Truco de Godot: Le metemos una propiedad dinámica al nodo para identificar su dirección
		area.set_meta("direccion_chunk", datos["dir"])
		
		# Conectamos la señal de colisión
		area.monitoring = false 
		
		area.body_entered.connect(_on_borde_chunk_entered.bind(area))
		add_child(area)
		
	# 🌟 CREAMOS UN PEQUEÑO TEMPORIZADOR DE SEGURIDAD
	# Espera 0.3 segundos antes de activar los sensores del mapa
	await get_tree().create_timer(0.3).timeout
	
	# Pasado el tiempo de cortesía, encendemos la detección en todas las áreas
	for child in get_children():
		if child is Area2D:
			child.monitoring = true
	print("🛡️ ¡Sensores de bordes activados de forma segura!")

func _on_borde_chunk_entered(body: Node2D, area_origen: Area2D):
	print("Llega on borde")
	if body is Player or body.is_in_group("grupo_jugador"):
		print("Llega on borde dentro de jugador")
		var direccion_viaje = area_origen.get_meta("direccion_chunk") as Vector2i
		var nuevo_centro = chunk_data.center_pos + (direccion_viaje * 3)
		
		# Accedemos a la referencia del mapa a través de los datos del chunk
		var mapa_global = chunk_data.world_reference
		
		if mapa_global and mapa_global.es_centro_valido(nuevo_centro):
			print("Cambiando de zona hacia: ", direccion_viaje)
			Global.transicion_chunk_solicitada.emit(direccion_viaje, nuevo_centro, chunk_data.world_reference)
			queue_free()
		else:
			print("¡No puedes ir por ahí! El mapa contiguo no es válido o es agua.")
			if "velocity" in body:
				body.global_position -= Vector2(direccion_viaje) * 20.0

func spawnear_cofre_inicial():
	# 1. Decisión de Mímico (30% probabilidad)
	var es_mimic = randf() < 0.3 
	var escena_a_instanciar = COFRE_MIMIC if es_mimic else COFRE_NORMAL
	var nuevo_objeto = escena_a_instanciar.instantiate()

	# 2. Obtener lista de casillas de tierra disponibles en el chunk actual
	var tierras = chunk_data.chunkTiles
	var casillas_tierra = []
	
	# Recorremos la matriz para buscar coordenadas con tileId de tierra (0, 1 o 2)
	for x in range(tierras.size()):
		for y in range(tierras[x].size()):
			var tile = tierras[x][y]
			if tile.tileId.x in [0, 1, 2]:
				# Guardamos la posición lógica (x,y)
				casillas_tierra.append(Vector2i(x, y))

	# 3. Elegir una posición segura
	var posicion_valida = false
	var intentos = 0
	var destino_pos = Vector2.ZERO
	
	while not posicion_valida and intentos < 50:
		var casilla = casillas_tierra[randi() % casillas_tierra.size()]
		# Convertimos la casilla a posición global en píxeles (escala 100)
		destino_pos = map_to_local(casilla * 100)
		
		# Comprobamos que el cofre esté a una distancia prudente del jugador (ej: al menos 150 px)
		if destino_pos.distance_to(Player.global_position) > 150:
			posicion_valida = true
		intentos += 1
	
	# Si no encontramos sitio en 50 intentos, lo ponemos cerca del jugador como fallback
	if not posicion_valida:
		var offset = Vector2(150, 0).rotated(randf() * 2 * PI)
		destino_pos = Player.global_position + offset

	# 4. Asignar posición y añadir al árbol
	nuevo_objeto.global_position = destino_pos
	add_child(nuevo_objeto)

	if es_mimic:
		print("¡Cuidado! Ha aparecido un Mímico.")

func calcular_punto_spawn_tierra():
	# 1. Extraemos todas las casillas que son tierra en una sola línea limpia
	var tierras = chunk_data.chunkTiles.duplicate() # Evitamos alterar la matriz original
	var casillas = []
	for row in tierras: casillas.append_array(row.filter(func(tile): return tile.tileId.x in [0, 1, 2]))
	
	if casillas.is_empty(): 
		print("Casillas vacio")
		return
	
	# 2. Elegimos una casilla lógica al azar
	var casilla_elegida = casillas[randi() % casillas.size()].coordinates
	
	# 3. Calculamos la posición real escalada (100) con el offset aleatorio centrado
	posicion_spawn_jugador = map_to_local(casilla_elegida + Vector2i(randi_range(35, 65), randi_range(35, 65)))
	print(posicion_spawn_jugador)
						
func spawnear_jugador(vector_entrada, es_posicion_directa: bool):
	if not jugador: return
	
	for child in jugador.get_children():
		if child is Camera2D:
			child.queue_free()
	if jugador.get_parent():
		jugador.get_parent().remove_child(jugador) 
		
	add_child(jugador)
	Player = jugador.get_child(0)
	
	# FLUJO A: Recibimos un Vector2 de coordenadas reales exactas
	if es_posicion_directa:
		jugador.global_position = vector_entrada as Vector2
		print("🎯 Jugador cargado directamente desde posición guardada: ", jugador.global_position)
	# FLUJO B: Recibimos un Vector2i con la dirección cardinal de tránsito
	else:
		var direccion_entrada = vector_entrada as Vector2i
		var tam_tile = tile_set.tile_size.x
		var ancho_px = 3 * 100 * tam_tile
		var alto_px = 3 * 100 * tam_tile
		var margen = 90.0 
		
		if direccion_entrada == Vector2i.ZERO:
			calcular_punto_spawn_tierra()
			jugador.global_position = posicion_spawn_jugador
		else:
			if direccion_entrada == Vector2i(1, 0):    
				jugador.global_position = Vector2(margen, alto_px / 2.0)
			elif direccion_entrada == Vector2i(-1, 0): 
				jugador.global_position = Vector2(ancho_px - margen, alto_px / 2.0)
			elif direccion_entrada == Vector2i(0, 1):  
				jugador.global_position = Vector2(ancho_px / 2.0, margen)
			elif direccion_entrada == Vector2i(0, -1): 
				jugador.global_position = Vector2(ancho_px / 2.0, alto_px - margen)

	var camera = Camera2D.new()
	camera.enabled = true
	camera.position = Vector2.ZERO
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	jugador.add_child(camera)
	spawnear_cofre_inicial()
		
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
