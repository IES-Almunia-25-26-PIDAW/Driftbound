extends Node

var score: int = 0
var chunk_actual: Chunk = null
var Player
# --- VARIABLES INTERNAS PARA EL CACHÉ DE GUARDADO ---
var current_chunk_center := Vector2i.ZERO
var player_global_position := Vector2.ZERO

# --- SEÑALES DEL FLUJO ---
signal score_changed(nuevo_score)
signal transicion_chunk_solicitada(direccion: Vector2i, centro: Vector2i, World: WordlMap)
signal solicitud_guardado_persistente() # Alerta al controlador para escribir en disco
signal volver_al_menu_solicitado()

func sumar_puntos(cantidad: int):
	score += cantidad
	score_changed.emit(score)

func establecer_chunk_actual(chunk: Chunk) -> void:
	chunk_actual = chunk

# --- NUEVA FUNCIÓN COMPARTIDA PARA ACTUALIZAR DATOS EN MEMORIA ---
func actualizar_datos_guardado(centro: Vector2i, pos_jugador: Vector2):
	current_chunk_center = centro
	player_global_position = pos_jugador

# --- FUNCIÓN DISPARADORA DEL PROCESO DE GUARDADO ---
func solicitar_guardado():
	solicitud_guardado_persistente.emit()
	
func solicitar_volver_al_menu():
	volver_al_menu_solicitado.emit()
