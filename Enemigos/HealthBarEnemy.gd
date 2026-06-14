extends TextureProgressBar

@export var health_component : HealthComponent

func _ready() -> void:
	
	max_value = health_component.maxHealth
	value = health_component.currentHealth

	health_component.onHealthChanged.connect(update_health)

func update_health(current_health):
	value = current_health

	if value <= 0:
		hide()
