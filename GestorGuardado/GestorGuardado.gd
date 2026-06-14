extends Node
class_name SaveManager

const SAVE_DIR = "user://save_game/"
const MAP_FILE = SAVE_DIR + "world_map.json"
const STATE_FILE = SAVE_DIR + "player_state.json"
const CHUNK_DIR = SAVE_DIR + "chunks/"

static func _ensure_dir_exists():
	if not DirAccess.dir_exists_absolute(CHUNK_DIR):
		DirAccess.make_dir_recursive_absolute(CHUNK_DIR)

# --- GUARDAR Y CARGAR EL ESTADO DEL JUGADOR Y SPAWN ---
static func save_player_state(spawn_pt: Vector2i, chunk_ctr: Vector2i, in_chunk: bool, player_rel_pos: Vector2):
	_ensure_dir_exists()
	
	var state_data = {
		"spawn_point_x": spawn_pt.x,
		"spawn_point_y": spawn_pt.y,
		"current_chunk_center_x": chunk_ctr.x,
		"current_chunk_center_y": chunk_ctr.y,
		"is_player_in_chunk": in_chunk,
		"player_relative_pos_x": player_rel_pos.x,
		"player_relative_pos_y": player_rel_pos.y
	}
	
	var file = FileAccess.open(STATE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state_data))
		file.close()
		print("Estado del jugador guardado.")

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
		print("Mapa global guardado con éxito.")

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

# --- GUARDAR Y CARGAR CHUNKS ---
static func save_chunk(chunk: Chunk):
	_ensure_dir_exists()
	var file_path = CHUNK_DIR + "chunk_%d_%d.json" % [chunk.center_pos.x, chunk.center_pos.y]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(chunk.to_dict()))
		file.close()
		print("Chunk [%d, %d] guardado." % [chunk.center_pos.x, chunk.center_pos.y])

static func load_chunk(center: Vector2i) -> Dictionary:
	var file_path = CHUNK_DIR + "chunk_%d_%d.json" % [center.x, center.y]
	if not FileAccess.file_exists(file_path):
		return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	json.parse(json_string)
	return json.get_data()
