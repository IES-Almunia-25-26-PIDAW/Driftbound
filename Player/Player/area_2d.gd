extends Area2D
class_name HitboxComponentPlayer

@export var damage: int = 1	

func _ready() -> void:
	#hitbox detecta areas HealtComponent Areas
	area_entered.connect(hit)
	
func hit(area):
	if area is HealthComponent:
		area.takeDamage(damage)
		
		var enemigo = area.get_parent()
		if enemigo and enemigo.has_method("aplicar_efecto_rojo"):
			enemigo.aplicar_efecto_rojo()
			
		# --- NUEVA LÍNEA: Le avisamos al enemigo de que sufra el empujón ---
		if enemigo and enemigo.has_method("recibir_knockback"):
			enemigo.recibir_knockback()
