extends Node
class_name StaminaComponent

signal onStaminaChanged(current_stamina: float)

@export var maxStamina: float = 100.0
var currentStamina: float = 100.0

var velocidad_gasto: float = 35.0
var velocidad_recarga: float = 20.0
var bloqueado_por_agotamiento: bool = false

func _ready() -> void:
	currentStamina = maxStamina

func gastar_o_recuperar(esta_corriendo: bool, se_esta_moviendo: bool, delta: float) -> float:
	if esta_corriendo and se_esta_moviendo and not bloqueado_por_agotamiento:
		currentStamina -= velocidad_gasto * delta
		if currentStamina <= 0:
			currentStamina = 0
			bloqueado_por_agotamiento = true
	else:
		currentStamina += velocidad_recarga * delta
		if currentStamina >= maxStamina:
			currentStamina = maxStamina
			bloqueado_por_agotamiento = false
		# Quitamos el print de recarga para no inundar la consola si está quieto
			
	# Emitimos la señal
	onStaminaChanged.emit(currentStamina)
	return currentStamina
