extends Node

var chunk_scene = preload("res://ChunkScene/ChunkScene.tscn")
var WorldGenerator = preload("res://World/TileMap.tscn")
var Menu = preload("res://MenuInicio/menu_principal.tscn")

const SAVE_DIR_PATH = "user://save_game/"

var World : WordlMap
var spawnPoint : Vector2i
var WorldScene
var MenuScene

var saved_world
var saved_state

# Variables de control de estado del juego
var is_in_chunk: bool = false
var current_chunk_center: Vector2i
var active_tilemap_node = null 
var exito_carga: bool = false


func _ready() -> void:
	# Conectamos las señales globales de guardado y transición
	Global.solicitud_guardado_persistente.connect(_on_solicitud_guardado_recibida)
	Global.transicion_chunk_solicitada.connect(_on_transicion_solicitada_desde_global)
	Global.volver_al_menu_solicitado.connect(_on_volver_al_menu_solicitada)
	
	# Comprobamos si existen archivos válidos para el menú principal
	exito_carga = cargar_partida_guardada()
	
	MenuScene = Menu.instantiate()
	MenuScene.partida_guardada_existe = exito_carga
	MenuScene.nueva_partida_pulsada.connect(_on_nueva_partida_solicitada)
	MenuScene.cargar_partida_pulsada.connect(_on_cargar_partida_solicitada)
	
	get_tree().current_scene.add_child(MenuScene)

func Instanciar_Menu():
	MenuScene = Menu.instantiate()
	MenuScene.partida_guardada_existe = exito_carga
	MenuScene.nueva_partida_pulsada.connect(_on_nueva_partida_solicitada)
	MenuScene.cargar_partida_pulsada.connect(_on_cargar_partida_solicitada)
	
	get_tree().current_scene.add_child(MenuScene)
	get_tree().paused = false

func _on_volver_al_menu_solicitada():
	# 1. Reseteamos los estados de control del Main
	is_in_chunk = false
	current_chunk_center = Vector2i.ZERO
	Global.chunk_actual = null
	active_tilemap_node = null

	# 2. LIMPIEZA AGRESIVA DEL ÁRBOL DE ESCENAS:
	# Vamos a recorrer todos los hijos de Main. Si no es el menú principal, se va fuera.
	for hijo in get_children():
		if hijo != MenuScene:
			print("🗑️ Eliminando nodo residual: ", hijo.name)
			hijo.queue_free()
			# Forzamos a que deje de ser hijo en este instante para que no interfiera
			remove_child(hijo) 

	# 3. ASEGURAR QUE WORLDGENERATOR NO EXISTA EN EL SCENETREE GLOBAL
	# Tu script original hacía: get_tree().current_scene.add_child(WorldScene)
	# Eso significa que el generador del mundo se añade a la RAÍZ de la escena actual, NO dentro de Main.
	# Vamos a buscarlo en la raíz del árbol para fulminarlo si sigue vivo:
	var root = get_tree().current_scene
	if root:
		for hijo_raiz in root.get_children():
			# Buscamos por el nombre del nodo que genera tu TileMap (ajusta si se llama distinto, ej: "WorldGenerator")
			if hijo_raiz.name.contains("TileMap") or hijo_raiz.name.contains("World"):
				if hijo_raiz != self: # No queremos borrarnos a nosotros mismos (Main)
					print("💥 Fulminando generador de mundo duplicado en la raíz: ", hijo_raiz.name)
					hijo_raiz.queue_free()

	# 4. Volvemos a poner a cero las referencias locales de seguridad
	WorldScene = null

	# 5. Comprobamos si hay partida guardada actualizada
	exito_carga = cargar_partida_guardada()
	
	# 6. Instanciamos el menú principal limpio
	Instanciar_Menu()
	
	# 6. Llamamos a tu función para re-instanciar el menú limpiamente
	Instanciar_Menu()

# --- RECEPTOR DE GUARDADO INTEGRADO ---
func _on_solicitud_guardado_recibida():
	if World == null:
		print("⚠️ No hay datos de mundo para guardar.")
		return
		
	# 1. Nos aseguramos de mantener el mapa general actualizado en disco
	SaveManager.save_world_map(World)
	
	# 2. Guardamos el estado unificado en memoria hacia el archivo JSON
	SaveManager.save_game_state()


func _on_transicion_solicitada_desde_global(direccion: Vector2i, centro: Vector2i, _world_ref: WordlMap):
	is_in_chunk = true
	current_chunk_center = centro
	# Al transicionar, enviamos falso en la carga directa para que use el vector de dirección lógica
	cargar_nuevo_chunk(centro, direccion, false)


# 🌟 FUNCIÓN UNIFICADA Y AMBIVALENTE DE INSTANCIACIÓN ---
func cargar_nuevo_chunk(centro: Vector2i, vector_ambivalente, es_carga_directa: bool):
	# Si había un mapamundi global visible en pantalla, lo ocultamos
	if is_instance_valid(WorldScene):
		WorldScene.visible = false
		
	var chunk_data = Chunk.new(centro, World)
	var instancia = chunk_scene.instantiate()
	var nuevo_chunk_manager = instancia.get_node("TileMap")
	
	# Conectamos tu función de ocultación por compatibilidad
	nuevo_chunk_manager.connect("creandoChunk", Callable(self, "oncreandoChunk"))
	
	get_tree().current_scene.add_child(instancia)
	
	# Delegamos por completo el flujo y el spawn al setup del ChunkManager
	nuevo_chunk_manager.setup(chunk_data, vector_ambivalente, es_carga_directa)
	active_tilemap_node = nuevo_chunk_manager


# --- INTERFACES DEL MENÚ PRINCIPAL ---
func _on_nueva_partida_solicitada() -> void:
	print("Menú nos avisa: ¡El jugador quiere una nueva partida!")
	if is_instance_valid(MenuScene):
		MenuScene.queue_free()
	crear_nueva_partida()


func _on_cargar_partida_solicitada() -> void:
	print("Menú nos avisa: ¡El jugador quiere cargar una partida!")
	if is_instance_valid(MenuScene):
		MenuScene.queue_free()
	
	# Ejecutamos la inicialización real de los nodos del juego
	IniciarPartidaCargada()


func IniciarPartidaCargada():
	if not saved_state.is_empty():
		is_in_chunk = saved_state.get("is_player_in_chunk", false)
		current_chunk_center = Vector2i(saved_state["current_chunk_center_x"], saved_state["current_chunk_center_y"])
		
		if is_in_chunk:
			print("🎯 Cargando partida: Reanudando en el Chunk activo: ", current_chunk_center)
			var pos_real_jugador = Vector2(saved_state["player_relative_pos_x"], saved_state["player_relative_pos_y"])
			
			# Activamos el flujo de carga directa usando la posición exacta guardada
			cargar_nuevo_chunk(current_chunk_center, pos_real_jugador, true)
			return
			
	# Si no estaba en un chunk o el estado está vacío, cargamos el generador base del mapamundi
	print("🌍 Cargando jugador en el mapa global.")
	WorldScene = WorldGenerator.instantiate()
	get_tree().current_scene.add_child(WorldScene)
	
	var WorldScript = WorldScene.get_child(0)
	if not WorldScript.is_node_ready():
		await WorldScript.ready
		
	spawnPoint = WorldScript.getSpawnPoint()
	active_tilemap_node = WorldScript


# --- FLUJO DE CREACIÓN Y CONFIGURACIÓN ---
func crear_nueva_partida() -> void:
	print("--- Iniciando Nueva Partida de Raíz ---")
	_borrar_archivos_de_guardado()
	
	is_in_chunk = false
	current_chunk_center = Vector2i.ZERO
	
	WorldScene = WorldGenerator.instantiate()
	get_tree().current_scene.add_child(WorldScene)
	
	var WorldGen = WorldScene.get_child(0)
	if not WorldGen.is_node_ready():
		await WorldGen.ready 
	
	var WorldAndSpawnPoint = WorldGen.getWorldAndSpawnPoint()
	World = WorldAndSpawnPoint[0]
	spawnPoint = WorldAndSpawnPoint[1]
	
	active_tilemap_node = WorldGen
	
	# Guardado inmediato del mapa base inicializado
	SaveManager.save_world_map(World)
	
	current_chunk_center = spawnPoint
	is_in_chunk = true
	# Entrada normal: Enviamos dirección Vector2i.ZERO y flag en falso
	cargar_nuevo_chunk(current_chunk_center, Vector2i.ZERO, false)


func cargar_partida_guardada() -> bool:
	print("--- Comprobando Archivos JSON ---")
	saved_world = SaveManager.load_world_map()
	saved_state = SaveManager.load_player_state()
	
	if saved_world == null:
		print("❌ No existe ningún archivo de mapa guardado.")
		return false
		
	World = saved_world
	return true


func oncreandoChunk() -> void:
	if is_instance_valid(WorldScene):
		WorldScene.visible = false


func _borrar_archivos_de_guardado() -> void:
	var dir = DirAccess.open(SAVE_DIR_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("--- Carpeta de guardado limpiada ---")
