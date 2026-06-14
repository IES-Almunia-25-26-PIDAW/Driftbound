extends Node

var chunk_scene = preload("res://ChunkScene/ChunkScene.tscn")
var WorldGenerator = preload("res://World/TileMap.tscn")
var Menu = preload("res://MenuInicio/menu_principal.tscn")

const SAVE_DIR_PATH = "user://save_game/"

var first_chunk = false
var World : WordlMap
var currentChunk: Chunk = null
var spawnPoint : Vector2i
var WorldScene
var MenuScene
var WorldScript
var WorldNode

var saved_world
var saved_state

# Variables para controlar el estado actual del jugador
var is_in_chunk: bool = false
var current_chunk_center: Vector2i
var active_tilemap_node = null # Guardará la referencia al TileMap activo (Mundo o Chunk)
var exito_carga


func _ready() -> void:
	
	Global.transicion_chunk_solicitada.connect(_on_transicion_solicitada_desde_global)
	exito_carga = await cargar_partida_guardada()
	
	MenuScene = Menu.instantiate()
	
	MenuScene.partida_guardada_existe = exito_carga
	
	MenuScene.nueva_partida_pulsada.connect(_on_nueva_partida_solicitada)
	
	MenuScene.cargar_partida_pulsada.connect(_on_cargar_partida_solicitada)
	
	get_tree().current_scene.add_child(MenuScene)
	

func _on_transicion_solicitada_desde_global(direccion: Vector2i, centro: Vector2i ,World : WordlMap):
	cargar_nuevo_chunk(direccion, centro,World)

# Tu función de carga limpia (ya no necesita conectar señales manualmente)
func cargar_nuevo_chunk(direccion_viaje: Vector2i, centro: Vector2i, World : WordlMap):
	
	var chunk_data = Chunk.new(centro, World)
	var instancia = chunk_scene.instantiate()
	var nuevo_chunk_manager = instancia.get_node("TileMap")
	add_child(instancia)
	nuevo_chunk_manager.setup(chunk_data, direccion_viaje)
	

func _on_nueva_partida_solicitada() -> void:
	
	print("Menú nos avisa: ¡El jugador quiere una nueva partida!")
	
	# 1. Borramos el menú de la pantalla ya que vamos a empezar a jugar
	if is_instance_valid(MenuScene):
		MenuScene.queue_free()
	
	# 2. Llamamos a tu función (la que limpia la carpeta y crea el generador)
	crear_nueva_partida()
	
func _on_cargar_partida_solicitada() -> void:
	
	print("Menú nos avisa: ¡El jugador quiere cargar una partida!")
	
	# 1. Borramos el menú de la pantalla ya que vamos a empezar a jugar
	if is_instance_valid(MenuScene):
		MenuScene.queue_free()
	
	# 2. Llamamos a tu función (la que limpia la carpeta y crea el generador)
	cargar_partida_guardada()

#Funcion que se llamara en el Menu Inicial para cargar la partida
func IniciarPartidaCargada():
	
	#En el caso de que se haya guardado correctamente desde el chunk
	if not saved_state.is_empty():
		spawnPoint = Vector2i(saved_state["spawn_point_x"], saved_state["spawn_point_y"])
		is_in_chunk = saved_state["is_player_in_chunk"]
		current_chunk_center = Vector2i(saved_state["current_chunk_center_x"], saved_state["current_chunk_center_y"])
		
		if is_in_chunk:
			print("Cargando jugador directamente en el Chunk activo: ", current_chunk_center)
			var pos_relativa = Vector2(saved_state["player_relative_pos_x"], saved_state["player_relative_pos_y"])
			cargar_escena_chunk(current_chunk_center, pos_relativa)
			return
			
	#El jugador estaba en el mapa global (o no había estado guardado pero sí se habia creado un mapa)
	print("Cargando jugador en el mapa global.")
	WorldScene = WorldGenerator.instantiate()
	get_tree().current_scene.add_child(WorldScene)
	
	WorldScript = WorldScene.get_child(0)
	
	# Si no había estado de jugador, recuperamos el spawn por defecto del mapa inyectado
	if saved_state.is_empty():
		if not WorldScript.is_node_ready():
			await WorldScript.ready
		spawnPoint = WorldScript.getSpawnPoint()
		
	active_tilemap_node = WorldScene


# --- OPCIÓN A: CREAR PARTIDA DESDE CERO ---
func crear_nueva_partida() -> void:
	print("--- Iniciando Nueva Partida de Raíz ---")
	
	_borrar_archivos_de_guardado()
	
	# Resetear variables de control por si acaso
	is_in_chunk = false
	current_chunk_center = Vector2i.ZERO
	
	# Instanciar el generador (él se encargará de hacer el ruido simplex)
	WorldScene = WorldGenerator.instantiate()
	get_tree().current_scene.add_child(WorldScene)
	
	var WorldGen = WorldScene.get_child(0)
	
	if not WorldGen.is_node_ready():
		await WorldGen.ready 
	
	var WorldAndSpawnPoint = WorldGen.getWorldAndSpawnPoint()
	
	# Esperamos a que el generador haga su trabajo interno en su _ready()
	World = WorldAndSpawnPoint[0]
	spawnPoint = WorldAndSpawnPoint[1]
	
	active_tilemap_node = WorldGen
	
	# Guardamos el mapa base recién creado inmediatamente para que ya existan los archivos
	SaveManager.save_world_map(World)
	
	# Función auxiliar para limpiar la carpeta
func _borrar_archivos_de_guardado() -> void:
	# Intentamos abrir el directorio de guardado
	var dir = DirAccess.open(SAVE_DIR_PATH)
	
	if dir:
		# Comenzamos a listar los archivos dentro de la carpeta
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Nos aseguramos de borrar archivos y no subcarpetas (. y .. son referencias del sistema)
			if not dir.current_is_dir():
				var error = dir.remove(file_name)
				if error == OK:
					print("Archivo borrado con éxito: ", file_name)
				else:
					print("Error al intentar borrar el archivo: ", file_name, " Código de error: ", error)
			
			# Pasamos al siguiente archivo
			file_name = dir.get_next()
			
		dir.list_dir_end()
		print("--- Carpeta de guardado limpiada ---")
	else:
		print("No se encontraron partidas previas o la carpeta aún no existe. No hace falta borrar nada.")


# --- OPCIÓN B: CARGAR PARTIDA EXISTENTE ---
func cargar_partida_guardada() -> bool:
	print("--- Cargando Partida desde Archivos JSON ---")
	
	saved_world = SaveManager.load_world_map()
	saved_state = SaveManager.load_player_state()
	
	# Si no hay mapa base, no podemos cargar nada válido
	if saved_world == null:
		print("Error: No existe ningún archivo de mapa guardado.")
		return false
		
	# Restauramos la información del mapa y el estado
	World = saved_world
	
	return true


# --- PROCESO DE JUEGO Y ENTRADA ---
func _process(_delta: float) -> void:
	# Crear/entrar en el chunk del Spawn con ENTER (Solo si estamos en el mapa base)
	if Input.is_action_just_pressed("enter") and not is_in_chunk:
		current_chunk_center = spawnPoint
		is_in_chunk = true
		cargar_escena_chunk(current_chunk_center, Vector2.ZERO)
		
	# Guardado manual rápido (Tecla asignada a 'G')
	if Input.is_action_just_pressed("ui_text_completion_query"): 
		guardar_partida_completa()


func oncreandoChunk() -> void:
	if WorldScene:
		WorldScene.visible = false


func cargar_escena_chunk(center: Vector2i, player_pos: Vector2) -> void:
	currentChunk = Chunk.new(center, World)
	
	# Guardamos o actualizamos el archivo JSON de este chunk específico
	SaveManager.save_chunk(currentChunk)
	
	var scene = chunk_scene.instantiate()
	var tilemap = scene.get_node("TileMap")
	
	tilemap.connect("creandoChunk", Callable(self, "oncreandoChunk"))
	get_tree().current_scene.add_child(scene)
	
	# Configuramos el TileMap del chunk
	tilemap.setup(currentChunk, Vector2i.ZERO)
	
	# Si venimos de una carga, reposicionamos al jugador en sus coordenadas guardadas
	if player_pos != Vector2.ZERO and tilemap.jugador:
		tilemap.jugador.global_position = player_pos
		
	active_tilemap_node = tilemap


func guardar_partida_completa() -> void:
	if World == null:
		print("No hay datos de mundo para guardar.")
		return
		
	# 1. Guardar mapa general
	SaveManager.save_world_map(World)
	
	# 2. Recolectar datos de posición si está en un chunk
	var player_relative_position = Vector2.ZERO
	
	if is_in_chunk and active_tilemap_node != null:
		if active_tilemap_node.has_method("get_player_pos"):
			player_relative_position = active_tilemap_node.get_player_pos()
		
		# Guardamos el estado actual del chunk por si rompió/colocó bloques
		if currentChunk:
			SaveManager.save_chunk(currentChunk)
			
	# 3. Guardar el archivo de estado persistente
	SaveManager.save_player_state(
		spawnPoint, 
		current_chunk_center, 
		is_in_chunk, 
		player_relative_position
	)
	print("¡Progreso del mundo y jugador guardados correctamente!")
	
