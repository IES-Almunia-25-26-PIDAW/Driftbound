extends CanvasLayer # 🌟 CAMBIADO AQUÍ (Antes decía Control)
class_name GameOverScreen

# Cambia esta ruta por la ruta real de tu escena de menú principal
const MENU_PRINCIPAL_SCENE = "res://Menu/menu_principal.tscn" 

func _ready() -> void:
	# Nos aseguramos de que el ratón sea visible para que puedan pulsar los botones
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# 🔄 BOTÓN: INTENTARLO DE NUEVO
func _on_boton_reintentar_pressed() -> void:
	print("🔄 [Game Over] Botón 'Intentarlo de nuevo' pulsado.")
	pass

# 🏠 BOTÓN: VOLVER AL MENÚ
func _on_boton_menu_pressed() -> void:
	print("🏠 [Game Over] Volviendo al menú principal...")
	
	var error = get_tree().change_scene_to_file(MENU_PRINCIPAL_SCENE)
	if error != OK:
		print("⚠️ [Game Over ERROR] No se pudo cargar la escena del menú. Verifica la ruta en el script.")
