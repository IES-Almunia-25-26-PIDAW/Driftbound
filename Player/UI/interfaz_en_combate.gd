extends Control

# Asegúrate de que esta ruta sea la correcta hacia tu Label.
# Truco: Borra lo que hay después del '=' y arrastra el ScoreLabel 
# desde tu árbol de escenas aquí manteniendo pulsada la tecla CTRL.
@onready var score_label: Label = $MarginContainer2/ScoreLabel 

func _ready() -> void:
	# Forzamos una primera actualización nada más arrancar
	actualizar_texto()

func _process(delta: float) -> void:
	# En cada frame del juego, actualizamos el texto con lo que tenga el Global
	actualizar_texto()

func actualizar_texto():
	if score_label:
		# Leemos directamente la variable matemática que ya sabemos que funciona
		score_label.text = "Score: " + str(Global.score)
	else:
		# Si sale este print, es que la ruta de arriba ($MarginContainer2/ScoreLabel) está mal
		print("❌ Error crítico: ¡El script no encuentra el nodo ScoreLabel!")
