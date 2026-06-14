extends Area2D
class_name Proyectil

const SPRITE_FUEGO = preload("res://assets/sprites/FireBall.png")
const SPRITE_AGUA = preload("res://assets/sprites/WaterBall.png")
const SPRITE_TIERRA = preload("res://assets/sprites/StoneBall.png")

@onready var sprite_2d: Sprite2D = $Sprite2D

var velocidad: float = 300.0
var direccion: Vector2 = Vector2.RIGHT
var elemento: String = "Fuego"
var daño_impacto: int = 1 # Este valor lo va a cambiar el Player al disparar

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# 🔄 Cambiamos la textura pero SIN sobreescribir el 'daño_impacto' que nos pase el jugador
	match elemento:
		"Fuego":
			sprite_2d.texture = SPRITE_FUEGO
		"Agua":
			sprite_2d.texture = SPRITE_AGUA
		"Tierra":
			sprite_2d.texture = SPRITE_TIERRA
			# Si es tierra y no se ha modificado el daño base aún, le damos su bonus por defecto
			if daño_impacto <= 1: daño_impacto = 3
			
	rotation = direccion.angle()

func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta

func _on_body_entered(body: Node) -> void:
	if body.has_method("recibir_efecto_elemental"):
		print("🚀 Proyectil impacta con daño real enviado: ", daño_impacto)
		body.recibir_efecto_elemental(elemento, direccion, daño_impacto)
		queue_free()
	else:
		# Ignoramos si choca contra el área del imán o detectores
		if not body.is_in_group("grupo_jugador") and body.name != "AreaIman" and body.name != "DetectorProyectiles":
			queue_free()
