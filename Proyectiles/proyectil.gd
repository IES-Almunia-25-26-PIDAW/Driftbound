extends Area2D
class_name Proyectil

# --- 🖼️ Texturas de tus Proyectiles ---
# Carga aquí tus 3 sprites. Cambia las rutas "res://..." por las reales de tus archivos.
const SPRITE_FUEGO = preload("res://assets/sprites/FireBall.png")
const SPRITE_AGUA = preload("res://assets/sprites/WaterBall.png")
const SPRITE_TIERRA = preload("res://assets/sprites/StoneBall.png")

@onready var sprite_2d: Sprite2D = $Sprite2D

# --- Variables de Movimiento ---
var velocidad: float = 300.0
var direccion: Vector2 = Vector2.RIGHT
var elemento: String = "Fuego" # Puede ser: "Fuego", "Agua", "Tierra"
var daño_impacto: int = 1 # Daño por defecto

func _ready() -> void:
	# Conectamos la señal nativa de colisión de Area2D
	body_entered.connect(_on_body_entered)
	
	# 🔄 Cambiamos el sprite según el elemento asignado
	match elemento:
		"Fuego":
			sprite_2d.texture = SPRITE_FUEGO
			daño_impacto = 1
		"Agua":
			sprite_2d.texture = SPRITE_AGUA
			daño_impacto = 1
		"Tierra":
			sprite_2d.texture = SPRITE_TIERRA
			daño_impacto = 3
	rotation = direccion.angle()

func _physics_process(delta: float) -> void:
	# Movimiento rectilíneo constante
	position += direccion * velocidad * delta

func _on_body_entered(body: Node) -> void:
	# Si choca con un enemigo, le pasamos el elemento y la dirección del golpe
	if body.has_method("recibir_efecto_elemental"):
		# 🌟 LE PASAMOS EL DAÑO BASE AL ENEMIGO AQUÍ
		body.recibir_efecto_elemental(elemento, direccion, daño_impacto)
		queue_free()
	else:
		queue_free()
