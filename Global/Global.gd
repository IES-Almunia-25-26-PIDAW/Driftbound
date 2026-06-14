extends Node

var score: int = 0

signal score_changed(nuevo_score)

func sumar_puntos(cantidad:int):
	score += cantidad
	score_changed.emit(score)
