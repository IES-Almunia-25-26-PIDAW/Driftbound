extends TextureProgressBar

func _ready() -> void:
	max_value = 100.0
	value = 100.0
	
	# Esperamos un instante a que el jugador aparezca en el mapa (igual que tu estamina)
	await get_tree().create_timer(0.05).timeout
	
	# 🌟 ¡AQUÍ ESTÁ EL TRUCO! Buscamos en TU grupo real: "grupo_jugador"
	var lista_jugadores = get_tree().get_nodes_in_group("grupo_jugador")
	
	if lista_jugadores.size() > 0:
		var player_nodo = lista_jugadores[0] as Player
		var componente = player_nodo.mana_component # Accedemos a tu variable limpia
		
		if componente:
			max_value = componente.maxMana
			value = componente.currentMana
			# Nos conectamos a la señal que configuramos en el StaminaComponent
			componente.onManaChanged.connect(update_mana)
			print("🔵 ¡ManaBar conectada con éxito usando tu grupo de jugadores!")
	else:
		print("❌ Error: Seguimos sin encontrar el grupo 'grupo_jugador'. Revisa que el Player lo tenga.")

# Esta función se ejecuta automáticamente cada vez que el maná cambia o se recarga
func update_mana(current_mana: float) -> void:
	value = current_mana
