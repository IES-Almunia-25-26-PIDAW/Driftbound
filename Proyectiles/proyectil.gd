extends Area2D
class_name Proyectil

const SPRITE_FUEGO = preload("res://assets/sprites/FireBall.png")
const SPRITE_AGUA = preload("res://assets/sprites/WaterBall.png")
const SPRITE_TIERRA = preload("res://assets/sprites/StoneBall.png")

@onready var sprite_2d: Sprite2D = $Sprite2D

var velocidad: float = 300.0
var direccion: Vector2 = Vector2.RIGHT
var elemento: String = "Fuego"
var daño_impacto: int = 1 

func _ready() -> void:
	# 🌟 CONEXIONES DOBLES: Escuchamos tanto cuerpos sólidos como áreas detectoras
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Nos añadimos al grupo por si otros scripts lo comprueban por grupo
	add_to_group("proyectiles")
	
	match elemento:
		"Fuego":
			sprite_2d.texture = SPRITE_FUEGO
		"Agua":
			sprite_2d.texture = SPRITE_AGUA
		"Tierra":
			sprite_2d.texture = SPRITE_TIERRA
			if daño_impacto <= 1: daño_impacto = 3
			
	rotation = direccion.angle()

func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta

# 🌟 1. DETECCIÓN DE CUERPOS SÓLIDOS (Enemigos, Mímicos, Paredes, etc.)
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("grupo_jugador") or body == self: 
		return

	# Si el cuerpo sólido tiene el método del mímico/enemigo
	if body.has_method("recibir_efecto_elemental"):
		body.recibir_efecto_elemental(elemento, direccion, daño_impacto)
		queue_free()
		return
		
	# Si el cuerpo sólido es el propio cofre directamente
	elif body.has_method("recibir_disparo_cofre"):
		body.recibir_disparo_cofre()
		queue_free()
		return
		
	# Si choca contra paredes o suelo del mapa
	elif body is TileMap or body is StaticBody2D:
		queue_free()
		return

# 🌟 2. DETECCIÓN DE ÁREAS (Como el DetectorProyectiles de tu Cofre)
func _on_area_entered(area: Area2D) -> void:
	# Ignoramos áreas del propio jugador o imanes
	if area.is_in_group("grupo_jugador") or area.name == "AreaIman": 
		return
	
	# Si el área pertenece a un cofre normal, o su padre es el cofre
	if area.has_method("recibir_disparo_cofre"):
		area.recibir_disparo_cofre()
		queue_free()
		return
	elif area.get_parent() and area.get_parent().has_method("recibir_disparo_cofre"):
		area.get_parent().recibir_disparo_cofre()
		queue_free()
		return
