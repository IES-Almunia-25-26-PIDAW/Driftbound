extends Area2D
class_name ItemRecogible

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var tipo_objeto: String = "curacion" # "curacion", "vida_max", "daño"
@export var valor_efecto: float = 25.0
@export var velocidad_atraccion: float = 300.0

var jugador_objetivo: Node2D = null
var siendo_atraido: bool = false

func _ready() -> void:
	# Configuramos el sprite correcto usando tu spritesheet único
	if sprite_2d:
		sprite_2d.hframes = 3
		sprite_2d.vframes = 1
		match tipo_objeto:
			"vida_max": sprite_2d.frame = 0 # Corazón entero
			"curacion": sprite_2d.frame = 1 # Poción
			"daño":     sprite_2d.frame = 2 # Espada
	
	# Conectamos la detección del imán del jugador
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# Si entra en el rango del imán del jugador, se activa la atracción
	if area.name == "AreaIman" or area.get_parent().is_in_group("grupo_jugador"):
		var padre = area.get_parent()
		if padre.is_in_group("grupo_jugador"):
			jugador_objetivo = padre
			siendo_atraido = true

func _physics_process(delta: float) -> void:
	if siendo_atraido and jugador_objetivo:
		# Volamos hacia el jugador
		var direccion = global_position.direction_to(jugador_objetivo.global_position)
		global_position += direccion * velocidad_atraccion * delta
		
		# 🌟 SOLUCIÓN: Si estamos extremadamente cerca del jugador, nos consume
		if global_position.distance_to(jugador_objetivo.global_position) < 15.0:
			aplicar_premio_al_jugador()

func aplicar_premio_al_jugador() -> void:
	if not jugador_objetivo: return
	
	var texto_pantalla = ""
	var color_texto = Color.WHITE
	
	# Aplicamos los efectos llamando a las funciones de tu Player
	match tipo_objeto:
		"vida_max":
			if jugador_objetivo.has_method("aumentar_vida_maxima"):
				jugador_objetivo.aumentar_vida_maxima(valor_efecto)
			texto_pantalla = "+2 Vida Máx"
			color_texto = Color.GREEN_YELLOW
		"curacion":
			if jugador_objetivo.has_method("curar_vida"):
				jugador_objetivo.curar_vida(valor_efecto)
			texto_pantalla = "+3 Salud"
			color_texto = Color.GREEN
		"daño":
			if jugador_objetivo.has_method("aumentar_daño_base"):
				jugador_objetivo.aumentar_daño_base(int(valor_efecto))
			texto_pantalla = "+3 Daño Base"
			color_texto = Color.RED
			
	# 🌟 CREAR MENSAJE IN-GAME FLOTANTE
	crear_texto_flotante(texto_pantalla, color_texto)
	
	# 🌟 SOLUCIÓN: El objeto desaparece limpiamente del mapa
	queue_free()

# Función auxiliar para pintar el texto en pantalla de forma bonita
func crear_texto_flotante(texto: String, color: Color) -> void:
	var label = Label.new()
	label.text = texto
	label.global_position = global_position + Vector2(-40, -20) # Centrado sobre el item
	
	# Le damos color e importancia visual
	label.modulate = color
	label.add_theme_font_size_override("font_size", 14) 
	
	# Lo añadimos al mapa directamente
	get_tree().current_scene.add_child(label)
	
	# Animación básica hacia arriba usando un Tween de Godot 4.5
	var tween = get_tree().create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -30), 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8) # Desvanecer (Fade out)
	tween.tween_callback(label.queue_free) # Borrar el texto cuando termine la animación
