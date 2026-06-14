extends Node

var score: int = 0
var chunk_actual: Chunk = null

signal score_changed(nuevo_score)
signal transicion_chunk_solicitada(direccion: Vector2i, centro: Vector2i ,World : WordlMap)

func sumar_puntos(cantidad:int):
	score += cantidad
	score_changed.emit(score)

func establecer_chunk_actual(chunk: Chunk) -> void:
	chunk_actual = chunk
