extends Node
class_name SaveManager

const SAVE_DIR = "user://save_game/"
const MAP_FILE = SAVE_DIR + "world_map.json"
const STATE_FILE = SAVE_DIR + "player_state.json"

static func _ensure_dir_exists():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# --- 🌟 NUEVO ENFOQUE: GUARDADO PERSISTENTE DESDE GLOBAL ---
# Esta función lee directamente del Global. Se llama desde el Main mediante señales.
static func save_game_state():
	_ensure_dir_exists()
	
	var state_data = {
		"spawn_point_x": 0, # Lo mantenemos por estructura, pero el spawn real ahora se calcula o lee de las variables dinámicas
		"spawn_point_y": 0,
		"current_chunk_center_x": Global.current_chunk_center.x,
		"current_chunk_center_y": Global.current_chunk_center.y,
		"is_player_in_chunk": true, # El flag que le dice al Main que debe cargar el flujo del chunk
		"player_relative_pos_x": Global.Player.global_position.x,
		"player_relative_pos_y": Global.Player.global_position.y
	}
	
	var file = FileAccess.open(STATE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state_data))
		file.close()
		print("💾 [SaveManager] Estado del juego (mundo y jugador) sincronizado con éxito desde el Global.")
	else:
		print("❌ [SaveManager] Error crítico: No se pudo escribir el archivo de estado.")

# --- CARGAR EL ESTADO DEL JUGADOR Y CHUNKS ---
static func load_player_state() -> Dictionary:
	if not FileAccess.file_exists(STATE_FILE):
		return {}
	var file = FileAccess.open(STATE_FILE, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) == OK:
		return json.get_data()
	return {}

# --- GUARDAR Y CARGAR EL MAPA GLOBAL ---
static func save_world_map(world: WordlMap):
	_ensure_dir_exists()
	var map_data = []
	for column in world.Map:
		var column_data = []
		for tile in column:
			column_data.append(tile.to_dict())
		map_data.append(column_data)
		
	var file = FileAccess.open(MAP_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(map_data))
		file.close()
		print("🌍 [SaveManager] Mapa global guardado con éxito.")

static func load_world_map() -> WordlMap:
	if not FileAccess.file_exists(MAP_FILE):
		return null
	var file = FileAccess.open(MAP_FILE, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return null
		
	var map_data = json.get_data()
	var new_world = WordlMap.new()
	for column_data in map_data:
		new_world.addMapColumn()
		for tile_data in column_data:
			var tile = WorldTile.from_dict(tile_data)
			new_world.setMap(tile)
	return new_world
