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
	Global.sumar_puntos(115)
	print("Puntos sumados el score actual es:", Global.score)
	get_parent().queue_free()
