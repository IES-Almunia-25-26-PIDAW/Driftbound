extends Node

# Precargamos la escena de muerte desde aquí arriba, a salvo de que borren al jugador
const GAME_OVER_SCENE = preload("res://GameOver/game_over.tscn") # <- Asegura tu ruta real

func desplegar_game_over() -> void:
	# Evitamos que se creen múltiples pantallas si se llama varias veces por ráfagas de golpes
	if get_tree().root.has_node("GameOver"):
		return
		
	print("🖥️ [GAME MANAGER] Instanciando pantalla de muerte en la raíz de forma segura.")
	var pantalla = GAME_OVER_SCENE.instantiate()
	
	# La hacemos visible justo antes de meterla al juego
	if "visible" in pantalla:
		pantalla.visible = true
	elif pantalla.has_node("FondoOscuro"): # Por si acaso, forzamos sus hijos
		pantalla.show()
		
	get_tree().root.add_child(pantalla)
