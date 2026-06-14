extends TextureProgressBar

func _ready() -> void:
	max_value = 100.0
	value = 100.0
	
	# Esperamos un instante a que el jugador aparezca en el mapa
	await get_tree().create_timer(0.05).timeout
	
	# Buscamos al jugador por su grupo
	var lista_jugadores = get_tree().get_nodes_in_group("grupo_jugador")
	
	if lista_jugadores.size() > 0:
		var player_nodo = lista_jugadores[0] as Player
		var componente = player_nodo.stamina_component
		
		if componente:
			max_value = componente.maxStamina
			value = componente.currentStamina
			componente.onStaminaChanged.connect(update_stamina)
			

func update_stamina(current_stamina: float) -> void:
	value = current_stamina
