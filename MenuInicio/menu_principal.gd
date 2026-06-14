extends Control

# --- Referencias a los botones principales ---
@onready var boton_continuar: Button = $VBoxContainer/BotonContinuar 
@onready var boton_configuracion: TextureButton = $BotonConfig # Modificado a TextureButton y fuera del VBox

# --- Referencias al Panel de Configuración ---
@onready var panel_controles: Panel = $PanelControles
@onready var boton_arriba: Button = $PanelControles/VBoxContainer/FilaArriba/BotonArriba
@onready var boton_abajo: Button = $PanelControles/VBoxContainer/FilaAbajo/BotonAbajo
@onready var boton_izquierda: Button = $PanelControles/VBoxContainer/FilaIzquierda/BotonIzquierda
@onready var boton_derecha: Button = $PanelControles/VBoxContainer/FilaDerecha/BotonDerecha
@onready var boton_correr: Button = $PanelControles/VBoxContainer/FilaCorrer/BotonCorrer
@onready var boton_atacar: Button = $PanelControles/VBoxContainer/FilaAtacar/BotonAtacar

var partida_guardada_existe: bool = false

#Señal para crear una nueva partida
signal nueva_partida_pulsada
#Señal para cargar una partida
signal cargar_partida_pulsada


# --- Rutas y Configuración ---
const ESCENA_JUEGO = "res://scenes/main/prueba_combate.tscn"

# Ajusta estos nombres si en tu "Mapa de Entradas" del proyecto los llamaste de otra forma
const ACCIONES = {
	"arriba": "w_move",
	"abajo": "s_move",
	"izquierda": "a_move",
	"derecha": "d_move",
	"correr": "correr",
	"atacar": "atacar"
}

var accion_esperando_tecla: String = ""

# --- Métodos Principales ---

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	actualizar_texto_botones_controles()
	
	# Comprobamos si hay una partida guardada
	if partida_guardada_existe:
		boton_continuar.disabled = false
	else:
		boton_continuar.disabled = true

# --- Lógica de Remapeo (Captura de teclado) ---

func _input(event: InputEvent) -> void:
	# Si el jugador clicó una acción y está esperando que pulse una tecla...
	if event is InputEventKey and event.is_pressed():
		print("Has pulsado la tecla: ", event.as_text(), " | Esperando acción: ", accion_esperando_tecla)
	if accion_esperando_tecla != "" and event is InputEventKey and event.is_pressed():
		# 1. Borramos la tecla anterior asignada a esa acción
		InputMap.action_erase_events(accion_esperando_tecla)
		# 2. Registramos la nueva tecla pulsada
		InputMap.action_add_event(accion_esperando_tecla, event)
		
		print("¡Guardando nueva tecla para la acción: ", accion_esperando_tecla)
		
		# 3. Reseteamos la espera y refrescamos los textos
		accion_esperando_tecla = ""
		actualizar_texto_botones_controles()
		get_viewport().set_input_as_handled() # Evita que la tecla haga otra acción en el menú

func actualizar_texto_botones_controles() -> void:
	boton_arriba.text = obtener_nombre_tecla(ACCIONES["arriba"])
	boton_abajo.text = obtener_nombre_tecla(ACCIONES["abajo"])
	boton_izquierda.text = obtener_nombre_tecla(ACCIONES["izquierda"])
	boton_derecha.text = obtener_nombre_tecla(ACCIONES["derecha"])
	boton_correr.text = obtener_nombre_tecla(ACCIONES["correr"])
	boton_atacar.text = obtener_nombre_tecla(ACCIONES["atacar"])

func obtener_nombre_tecla(accion: String) -> String:
	var eventos = InputMap.action_get_events(accion)
	if eventos.size() > 0:
		return eventos[0].as_text()
	return "[Sin Tecla]"

# --- Señales de los Botones Principales ---

func _on_boton_nueva_partida_pressed() -> void:
	nueva_partida_pulsada.emit()

func _on_boton_continuar_pressed() -> void:
	cargar_partida_pulsada.emit()

func _on_boton_salir_pressed() -> void:
	get_tree().quit()

func _on_boton_config_pressed() -> void:
	actualizar_texto_botones_controles()
	panel_controles.show() # Abre el menú de controles

func _on_boton_volver_pressed() -> void:
	panel_controles.hide() # Cierra el menú de controles e面 vuelve al principal

# --- Señales de la Pantalla de Configuración ---

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
