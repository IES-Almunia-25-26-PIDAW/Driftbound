extends CharacterBody2D
class_name Player

# --- Referencias ---
@onready var movement: Movement = $Movement as Movement
@onready var animation_player = $AnimationPlayer
@onready var attack_collision = $Area2D/CollisionShape2D
@onready var mana_bar: TextureProgressBar = $"MarginContainer4/ManaBar" 
@onready var elemento_icono: TextureRect = $"ElementoIcono"
@onready var mana_component: ManaComponent = $ManaComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent

const PROYECTIL_SCENE = preload("res://Proyectiles/proyectil.tscn") 

# --- Señales ---
signal elemento_cambiado(nuevo_elemento: String)

# --- Configuración del Personaje ---
var input_vector: Vector2	
var current_dir = "Abajo"  
var is_attacking = false
@export var walk_speed: float = 100.0
@export var run_speed: float = 180.0

# --- Variables de Estamina ---
var current_stamina: float = 100.0 # 🌟 Variable añadida que faltaba registrar

# --- Variables de Maná ---
var max_mana: float = 100.0
var current_mana: float = 100.0
var coste_proyectil: float = 15.0      
var velocidad_recarga_mana: float = 25.0 
var tiempo_espera_recarga: float = 2.0  
var contador_espera_mana: float = 0.0   

# --- Texturas de Elementos ---
const ICONO_FUEGO = preload("res://assets/sprites/FireBall.png")
const ICONO_AGUA = preload("res://assets/sprites/WaterBall.png")
const ICONO_TIERRA = preload("res://assets/sprites/StoneBall.png")

var elemento_seleccionado: String = "Fuego" 

func _ready():
	movement.setup(self)
	attack_collision.disabled = true 
	add_to_group("grupo_jugador")
	actualizar_interfaz_elemental()
	
	# Conexión remota de la interfaz de maná utilizando tu grupo nativo
	await get_tree().process_frame 
	var player = get_tree().get_first_node_in_group("grupo_jugador")
	if player and player.mana_component:
		player.mana_component.onManaChanged.connect(func(current):
			_on_mana_changed(current, player.mana_component.maxMana)
		)
		print("🔗 ¡ManaComponent conectado con éxito al HUD!")

func _process(delta): 
	if not is_attacking:
		input_vector.x = Input.get_axis("a_move", "d_move")
		input_vector.y = Input.get_axis("w_move", "s_move")
	else:
		input_vector = Vector2.ZERO

	# Ataque 
	if Input.is_action_just_pressed("atacar") and not is_attacking:
		atacar()
	
	if Input.is_action_just_pressed("Fuego"): 
		elemento_seleccionado = "Fuego"
		elemento_cambiado.emit("Fuego") 
	elif Input.is_action_just_pressed("Agua"): 
		elemento_seleccionado = "Agua"
		elemento_cambiado.emit("Agua")
	elif Input.is_action_just_pressed("Tierra"): 
		elemento_seleccionado = "Tierra"
		elemento_cambiado.emit("Tierra")
		
	if contador_espera_mana > 0:
		contador_espera_mana -= delta
	else:
		if current_mana < max_mana:
			current_mana = min(max_mana, current_mana + velocidad_recarga_mana * delta)
			actualizar_interfaz_elemental() 

func _physics_process(delta):
	# 1. Detectamos el input del teclado
	var quiere_correr = Input.is_action_pressed("correr")
	var se_esta_moviendo = input_vector != Vector2.ZERO
	
	# 2. Procesamos componentes
	if mana_component:
		mana_component.recuperar_y_procesar(delta)
		
	if stamina_component:
		# 🌟 CORREGIDO: Ahora usa 'quiere_correr' en vez de la variable inexistente
		current_stamina = stamina_component.gastar_o_recuperar(quiere_correr, se_esta_moviendo, delta)
	
	# 3. Aplicamos la velocidad según el estado de la estamina
	if quiere_correr and se_esta_moviendo and stamina_component and not stamina_component.bloqueado_por_agotamiento:
		movement.speed = run_speed
	else:
		movement.speed = walk_speed

	# Movemos al personaje
	movement.move(input_vector)

	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		actualizar_direccion(velocity)

	animation_player.play("Idle" + current_dir)

func actualizar_direccion(dir: Vector2):
	var angle = dir.angle()
	var deg = fmod(rad_to_deg(angle) + 360.0 , 360.0)
	
	if deg >= 315 or deg < 45:
		current_dir = "Derecha"
	elif deg < 135:
		current_dir = "Abajo"
	elif deg < 225:
		current_dir = "Izquierda"
	else:
		current_dir = "Arriba"

func atacar():
	if mana_component and not mana_component.gastar_mana(coste_proyectil):
		print("❌ ¡Sin maná suficiente en el Componente!")
		return

	is_attacking = true
	attack_collision.disabled = false 

	# 🌟 CORREGIDO: Borrada la duplicación. Ahora solo lanza UN proyectil por ataque
	lanzar_proyectil()
	
	contador_espera_mana = tiempo_espera_recarga
	actualizar_interfaz_elemental()
	
	match current_dir:
		"Abajo": animation_player.play("AtaqueFrontal") 
		"Arriba": animation_player.play("AtaquePosterior")
		"Izquierda": animation_player.play("AtaqueIzquierdo")
		"Derecha": animation_player.play("AtaqueDerecho")

func lanzar_proyectil():
	# 🌟 Recuerda quitar el 'as Proyectil' si Godot te vuelve a dar error de scope aquí
	var nuevo_proyectil = PROYECTIL_SCENE.instantiate() as Proyectil
	
	nuevo_proyectil.elemento = elemento_seleccionado
	
	match current_dir:
		"Abajo":     nuevo_proyectil.direccion = Vector2.DOWN
		"Arriba":    nuevo_proyectil.direccion = Vector2.UP
		"Izquierda": nuevo_proyectil.direccion = Vector2.LEFT
		"Derecha":   nuevo_proyectil.direccion = Vector2.RIGHT
		
	nuevo_proyectil.global_position = global_position
	get_tree().current_scene.add_child(nuevo_proyectil)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if "Ataque" in anim_name or anim_name == "AtaqueFrontal" or anim_name == "AtaquePosterior" or anim_name == "AtaqueIzquierdo" or anim_name == "AtaqueDerecho":
		is_attacking = false
		attack_collision.disabled = true 
		
func recibir_golpe_efecto():
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1, 0, 0, 1) 
		
	await get_tree().create_timer(0.2).timeout
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1, 1, 1, 1)

func actualizar_interfaz_elemental():
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = current_mana
		
	if elemento_icono:
		match elemento_seleccionado:
			"Fuego": elemento_icono.texture = ICONO_FUEGO
			"Agua":  elemento_icono.texture = ICONO_AGUA
			"Tierra": elemento_icono.texture = ICONO_TIERRA

func _on_mana_changed(current: float, maximo: float) -> void:
	max_mana = maximo
	current_mana = current
	actualizar_interfaz_elemental()
