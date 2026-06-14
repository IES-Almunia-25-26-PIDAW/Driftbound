extends TextureProgressBar

func _ready() -> void:
	max_value = 100.0
	value = 100.0

	await get_tree().create_timer(0.05).timeout

	var lista_jugadores = get_tree().get_nodes_in_group("grupo_jugador")

	if lista_jugadores.size() > 0:
		var player_nodo = lista_jugadores[0]
		var componente_vida = player_nodo.get_node("HealthComponent")

		if componente_vida:
			max_value = componente_vida.maxHealth # Revisa si su variable se llama maxHealth o max_health
			value = componente_vida.currentHealth # Revisa si se llama currentHealth o current_health

			componente_vida.onHealthChanged.connect(update_health)
			print("¡HealthBar conectada con éxito al jugador generado por código!")
	else:
		print(" Error: La barra de vida no encuentra al jugador. ¿Tu compañero se olvidó de añadirlo a 'grupo_jugador'?")

func update_health(current_health: float) -> void:
	value = current_health
