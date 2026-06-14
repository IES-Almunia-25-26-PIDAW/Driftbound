extends Area2D
class_name HitboxComponent

@export var damage: int = 1	

func _ready() -> void:
	# Conectamos la detección de áreas
	area_entered.connect(hit)
	
func hit(area):
	# 1. Si el jugador tiene un componente de salud (HealthComponent) en su área:
	if area is HealthComponent:
		area.takeDamage(damage)
	
	# 2. Buscamos el cuerpo del jugador para ponerlo en rojo
	# Asumiendo que el área del jugador es hija de su CharacterBody2D (Player)
	var jugador = area.get_parent()
	if jugador is Player and jugador.has_method("recibir_golpe_efecto"):
		jugador.recibir_golpe_efecto()
		
	# 3. Le decimos a NUESTRO propio padre (el enemigo actual) que se congele
	var mi_enemigo = get_parent()
	if mi_enemigo and mi_enemigo.has_method("congelar_por_ataque"):
		mi_enemigo.congelar_por_ataque()
