extends TextureRect

# 🌟 PRECARGA TUS SPRITES: Asegúrate de poner aquí las rutas reales de tus imágenes PNG
const SPRITE_FUEGO = preload("res://assets/sprites/FireBall.png") # Ajusta los nombres de tus archivos
const SPRITE_AGUA = preload("res://assets/sprites/WaterBall.png")
const SPRITE_TIERRA = preload("res://assets/sprites/StoneBall.png")

const MARCO_FUEGO = preload("res://assets/sprites/MarcoFuego.png") 
const MARCO_AGUA = preload("res://assets/sprites/MarcoAgua.png")
const MARCO_TIERRA = preload("res://assets/sprites/MarcoPiedra.png")

@onready var marco_padre: TextureRect = get_parent() as TextureRect

func _ready() -> void:
	# Ponemos el de fuego por defecto al empezar
	texture = SPRITE_FUEGO
	if marco_padre:
		marco_padre.texture = MARCO_FUEGO
	
	# Esperamos el instante de seguridad igual que tus barras
	await get_tree().create_timer(0.05).timeout
	
	# Buscamos al jugador en tu grupo real
	var lista_jugadores = get_tree().get_nodes_in_group("grupo_jugador")
	
	if lista_jugadores.size() > 0:
		var player_nodo = lista_jugadores[0] as Player
		
		# 🔗 CONEXIÓN: Nos sintonizamos a la señal que acabamos de crear en el jugador
		player_nodo.elemento_cambiado.connect(_on_elemento_cambiado)
		
		# Sincronizamos el elemento actual por si el jugador ya empezó con otro
		_on_elemento_cambiado(player_nodo.elemento_seleccionado)

# Esta función se ejecuta sola cada vez que pulsas 1, 2 o 3
func _on_elemento_cambiado(nuevo_elemento: String) -> void:
	match nuevo_elemento:
		"Fuego":
			texture = SPRITE_FUEGO
			if marco_padre: 
				marco_padre.texture = MARCO_FUEGO # Cambia el marco de fuera
		"Agua":
			texture = SPRITE_AGUA
			if marco_padre: 
				marco_padre.texture = MARCO_AGUA
		"Tierra":
			texture = SPRITE_TIERRA
			if marco_padre: 
				marco_padre.texture = MARCO_TIERRA
