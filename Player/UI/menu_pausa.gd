extends Control

# --- Referencias a los botones de pausa ---
@onready var boton_continuar: Button = $VBoxContainer/BotonContinuar
@onready var boton_configuracion: Button = $VBoxContainer/BotonConfiguracion
@onready var boton_menu_principal: Button = $VBoxContainer/BotonMenuPrincipal

# --- Referencias al Panel de Configuración Copiado ---
@onready var panel_controles: Panel = $PanelControles
@onready var boton_arriba: Button = $PanelControles/VBoxContainer/FilaArriba/BotonArriba
@onready var boton_abajo: Button = $PanelControles/VBoxContainer/FilaAbajo/BotonAbajo
@onready var boton_izquierda: Button = $PanelControles/VBoxContainer/FilaIzquierda/BotonIzquierda
@onready var boton_derecha: Button = $PanelControles/VBoxContainer/FilaDerecha/BotonDerecha
@onready var boton_correr: Button = $PanelControles/VBoxContainer/FilaCorrer/BotonCorrer
@onready var boton_atacar: Button = $PanelControles/VBoxContainer/FilaAtacar/BotonAtacar
@onready var boton_fuego: Button = $PanelControles/VBoxContainer/FilaFuego/BotonFuego
@onready var boton_agua: Button = $PanelControles/VBoxContainer/FilaAgua/BotonAgua
@onready var boton_tierra: Button = $PanelControles/VBoxContainer/FilaTierra/BotonTierra

const ESCENA_MENU = "res://scenes/main/menu_principal.tscn"

# Recuerda verificar que estos nombres coincidan con tu "Mapa de Entradas"
const ACCIONES = {
	"arriba": "w_move",
	"abajo": "s_move",
	"izquierda": "a_move",
	"derecha": "d_move",
	"correr": "correr",
	"atacar": "atacar",
	"fuego": "Fuego",
	"agua": "Agua",
	"tierra": "Tierra"
}

var accion_esperando_tecla: String = ""

func _ready() -> void:
	hide()
	actualizar_texto_botones_controles()

func _unhandled_input(event: InputEvent) -> void:
	# Si estamos esperando una tecla en la configuración de la pausa...
	if accion_esperando_tecla != "" and event is InputEventKey and event.is_pressed():
		InputMap.action_erase_events(accion_esperando_tecla)
		InputMap.action_add_event(accion_esperando_tecla, event)
		
		accion_esperando_tecla = ""
		actualizar_texto_botones_controles()
		get_viewport().set_input_as_handled()
		return # Cortamos aquí para que no cierre la pausa al remapear
		
	# Tecla para abrir/cerrar la pausa general
	if event.is_action_pressed("pausar"):
		if panel_controles.visible:
			# Si la configuración está abierta, el primer ESC solo cierra la configuración
			panel_controles.hide()
			_on_boton_volver_pressed()
		else:
			if visible:
				reanudar_juego()
			else:
				pausar_juego()

func pausar_juego() -> void:
	actualizar_texto_botones_controles() # Lee las teclas actuales antes de mostrarse
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

func reanudar_juego() -> void:
	panel_controles.hide() # Por si acaso se quedó abierto
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

# --- Lógica de lectura de teclas ---
func actualizar_texto_botones_controles() -> void:
	boton_arriba.text = obtener_nombre_tecla(ACCIONES["arriba"])
	boton_abajo.text = obtener_nombre_tecla(ACCIONES["abajo"])
	boton_izquierda.text = obtener_nombre_tecla(ACCIONES["izquierda"])
	boton_derecha.text = obtener_nombre_tecla(ACCIONES["derecha"])
	boton_correr.text = obtener_nombre_tecla(ACCIONES["correr"])
	boton_atacar.text = obtener_nombre_tecla(ACCIONES["atacar"])
	boton_fuego.text = obtener_nombre_tecla(ACCIONES["fuego"])
	boton_agua.text = obtener_nombre_tecla(ACCIONES["agua"])
	boton_tierra.text = obtener_nombre_tecla(ACCIONES["tierra"])

func obtener_nombre_tecla(accion: String) -> String:
	var eventos = InputMap.action_get_events(accion)
	if eventos.size() > 0:
		return eventos[0].as_text()
	return "[Sin Tecla]"

# --- Conexión de Señales del Menú de Pausa ---

func _on_boton_continuar_pressed() -> void:
	reanudar_juego()

func _on_boton_configuracion_pressed() -> void:
	panel_controles.show() # ¡Ahora sí abre la pantalla de controles!

func _on_boton_menu_principal_pressed() -> void:
	Global.solicitar_volver_al_menu()
	
func _on_boton_guardar_pressed() -> void:
	Global.solicitar_guardado()
# --- Conexión de Señales del Panel de Controles de Pausa ---

func _on_boton_volver_pressed() -> void:
	panel_controles.hide() # Cierra la configuración y vuelve a los botones de pausa
	$VBoxContainer.show()

func _on_boton_arriba_pressed() -> void:
	accion_esperando_tecla = ACCIONES["arriba"]
	boton_arriba.text = "...Pulsar tecla..."

func _on_boton_abajo_pressed() -> void:
	accion_esperando_tecla = ACCIONES["abajo"]
	boton_abajo.text = "...Pulsar tecla..."

func _on_boton_izquierda_pressed() -> void:
	accion_esperando_tecla = ACCIONES["izquierda"]
	boton_izquierda.text = "...Pulsar tecla..."

func _on_boton_derecha_pressed() -> void:
	accion_esperando_tecla = ACCIONES["derecha"]
	boton_derecha.text = "...Pulsar tecla..."

func _on_boton_correr_pressed() -> void:
	accion_esperando_tecla = ACCIONES["correr"]
	boton_correr.text = "...Pulsar tecla..."

func _on_boton_atacar_pressed() -> void:
	accion_esperando_tecla = ACCIONES["atacar"]
	boton_atacar.text = "...Pulsar tecla..."


func _on_boton_fuego_pressed() -> void:
	accion_esperando_tecla = ACCIONES["fuego"]
	boton_fuego.text = "...Pulsar tecla..."


func _on_boton_agua_pressed() -> void:
	accion_esperando_tecla = ACCIONES["agua"]
	boton_agua.text = "...Pulsar tecla..."


func _on_boton_tierra_pressed() -> void:
	accion_esperando_tecla = ACCIONES["tierra"]
	boton_tierra.text = "...Pulsar tecla..."
