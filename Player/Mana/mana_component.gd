extends Node
class_name ManaComponent

# Al igual que tu estamina, emite solo el flotante actual
signal onManaChanged(current_mana: float)

@export var maxMana: float = 100.0
var currentMana: float = 100.0

@export var velocidad_recarga: float = 25.0
@export var tiempo_espera_recarga: float = 2.0
var contador_espera: float = 0.0

func _ready() -> void:
	currentMana = maxMana

func gastar_mana(cantidad: float) -> bool:
	if currentMana >= cantidad:
		currentMana -= cantidad
		contador_espera = tiempo_espera_recarga # Reinicia el reloj de 2 segundos
		onManaChanged.emit(currentMana) # Emitimos cambio
		return true
	return false

func recuperar_y_procesar(delta: float) -> void:
	if contador_espera > 0:
		contador_espera -= delta
	else:
		if currentMana < maxMana:
			currentMana = min(maxMana, currentMana + velocidad_recarga * delta)
			onManaChanged.emit(currentMana) # Emitimos cambio al recargar
