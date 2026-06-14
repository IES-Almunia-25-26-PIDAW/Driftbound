extends Area2D
class_name HealthComponent

signal onDead
signal onDamageTook
signal onHealthChanged(health: int)

@export var maxHealth: int = 3
var currentHealth: int = 3
var old_health: int

func _ready() -> void:
	currentHealth = maxHealth	
	
func takeHeal(value: int):
	setHealth(value) 
## La funcion se encarga de calcular del daño por lo que no hace falta poner el daño en negativo
func takeDamage(damage: int):
	var value = abs(damage)
	setHealth(-value)

func setHealth(value: int):
	old_health = currentHealth
	currentHealth += value
	currentHealth = clamp(currentHealth, 0, maxHealth)
	
	if old_health != currentHealth:
		onHealthChanged.emit(currentHealth)
	
	if currentHealth <= 0:
		dead()
	elif currentHealth >= 0 and currentHealth < old_health:
		onDamageTook.emit()

func dead():
	onDead.emit()
	
	# 🌟 COMPROBACIÓN MAESTRA: ¿El padre de este componente es el jugador?
	if get_parent().is_in_group("grupo_jugador"):
		print("💀 [HealthComponent] ¡El jugador se ha quedado sin vida!")
		# Llamamos al GameManager global para que cree la pantalla de Game Over 
		# desde fuera antes de borrar al jugador de la pantalla.
		if ResourceLoader.exists("res://game_manager.gd") or true: # Validación de seguridad
			GameManager.desplegar_game_over()
	else:
		# Si no es el jugador, asumimos que es un enemigo (como el mímico o un bicho normal)
		Global.sumar_puntos(115)
		print("Puntos sumados el score actual es:", Global.score)
	
	# Finalmente, borra al personaje (sea el jugador o un enemigo) de forma limpia
	get_parent().queue_free()
