extends CharacterBody2D
class_name Player

# --- Referencias a Componentes y Nodos ---
@onready var movement: Movement = $Movement as Movement
@onready var animation_player = $AnimationPlayer
@onready var attack_collision = $Area2D/CollisionShape2D
@onready var mana_bar: TextureProgressBar = $"MarginContainer4/ManaBar" 
@onready var elemento_icono: TextureRect = $"ElementoIcono"
@onready var mana_component: ManaComponent = $ManaComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent

# 🌟 REFERENCIA ASIGNADA: El componente de salud para interactuar con los cofres/mímicos
@onready var health_component = $HealthComponent 

const PROYECTIL_SCENE = preload("res://Proyectiles/proyectil.tscn")
const GAME_OVER_SCENE = preload("res://GameOver/game_over.tscn")

# --- Señales ---
signal elemento_cambiado(nuevo_elemento: String)

# --- Configuración del Personaje ---
var input_vector: Vector2	
var current_dir = "Abajo"  
var is_attacking = false
@export var walk_speed: float = 100.0
@export var run_speed: float = 180.0

# 🌟 VARIABLE ASIGNADA: Almacena el daño extra permanente que te dan los cofres
var bonus_daño: int = 0

# --- Variables de Estamina ---
var current_stamina: float = 100.0

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

func _ready() -> void:
	# 1. Configuración física inicial
	movement.setup(self)
	attack_collision.disabled = true 
	
	# 2. Registro en el grupo nativo para el radar de los enemigos y los cofres
	add_to_group("grupo_jugador")
	actualizar_interfaz_elemental()
	
	# 3. CONEXIÓN CORREGIDA: Conexión interna del componente de maná sin bucles de grupo
	if mana_component:
		mana_component.onManaChanged.connect(_on_mana_changed_local)
		print("🔗 [Player] ManaComponent conectado internamente con éxito.")
	if health_component:
		if health_component.has_signal("onDeath"):
			health_component.onDeath.connect(_on_player_muerto)
		elif health_component.has_signal("on_death"):
			health_component.on_death.connect(_on_player_muerto)

func _process(delta: float) -> void: 
	if not is_attacking:
		input_vector.x = Input.get_axis("a_move", "d_move")
		input_vector.y = Input.get_axis("w_move", "s_move")
	else:
		input_vector = Vector2.ZERO

	# Sistema de Ataque 
	if Input.is_action_just_pressed("atacar") and not is_attacking:
		atacar()
	
	# Cambio de elementos por Input
	if Input.is_action_just_pressed("Fuego"): 
		elemento_seleccionado = "Fuego"
		elemento_cambiado.emit("Fuego") 
	elif Input.is_action_just_pressed("Agua"): 
		elemento_seleccionado = "Agua"
		elemento_cambiado.emit("Agua")
	elif Input.is_action_just_pressed("Tierra"): 
		elemento_seleccionado = "Tierra"
		elemento_cambiado.emit("Tierra")
		
	# Contador de retraso para la autoregeneración de maná
	if contador_espera_mana > 0:
		contador_espera_mana -= delta
	else:
		if current_mana < max_mana:
			current_mana = min(max_mana, current_mana + velocidad_recarga_mana * delta)
			actualizar_interfaz_elemental() 

func _physics_process(delta: float) -> void:
	var quiere_correr = Input.is_action_pressed("correr")
	var se_esta_moviendo = input_vector != Vector2.ZERO
	
	# Procesamiento modular de componentes de estado
	if mana_component:
		mana_component.recuperar_y_procesar(delta)
		
	if stamina_component:
		current_stamina = stamina_component.gastar_o_recuperar(quiere_correr, se_esta_moviendo, delta)
	
	# Gestión de velocidades según la estamina
	if quiere_correr and se_esta_moviendo and stamina_component and not stamina_component.bloqueado_por_agotamiento:
		movement.speed = run_speed
	else:
		movement.speed = walk_speed

	# Aplicamos el movimiento final mediante el script Movement
	movement.move(input_vector)

	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		actualizar_direccion(velocity)

	animation_player.play("Idle" + current_dir)

func actualizar_direccion(dir: Vector2) -> void:
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

func atacar() -> void:
	if mana_component and not mana_component.gastar_mana(coste_proyectil):
		print("❌ ¡Sin maná suficiente en el Componente!")
		return

	is_attacking = true
	attack_collision.disabled = false 

	# Disparamos el proyectil elemental
	lanzar_proyectil()
	
	contador_espera_mana = tiempo_espera_recarga
	actualizar_interfaz_elemental()
	
	match current_dir:
		"Abajo": animation_player.play("AtaqueFrontal") 
		"Arriba": animation_player.play("AtaquePosterior")
		"Izquierda": animation_player.play("AtaqueIzquierdo")
		"Derecha": animation_player.play("AtaqueDerecho")

func lanzar_proyectil() -> void:
	var nuevo_proyectil = PROYECTIL_SCENE.instantiate() as Proyectil
	nuevo_proyectil.elemento = elemento_seleccionado
	
	# 🌟 CORREGIDO: Buscamos 'daño_impacto' (que es como se llama en tu proyectil)
	var daño_base_elemento = 1
	if elemento_seleccionado == "Tierra": daño_base_elemento = 3
	
	nuevo_proyectil.daño_impacto = daño_base_elemento + bonus_daño
	print("⚔️ [Player] Disparando proyectil de ", elemento_seleccionado, " con Daño Total: ", nuevo_proyectil.daño_impacto)
	
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
		
func recibir_golpe_efecto() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1, 0, 0, 1) 
		
	await get_tree().create_timer(0.2).timeout
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1, 1, 1, 1)

func actualizar_interfaz_elemental() -> void:
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = current_mana
		
	if elemento_icono:
		match elemento_seleccionado:
			"Fuego": elemento_icono.texture = ICONO_FUEGO
			"Agua":  elemento_icono.texture = ICONO_AGUA
			"Tierra": elemento_icono.texture = ICONO_TIERRA

func _on_mana_changed_local(current: float) -> void:
	if mana_component:
		_on_mana_changed(current, mana_component.maxMana)

func _on_mana_changed(current: float, maximo: float) -> void:
	max_mana = maximo
	current_mana = current
	actualizar_interfaz_elemental()
	
# --- 🎁 MECÁNICAS DE RECOLECCIÓN (COFRES Y PREMIOS) ---

func aumentar_vida_maxima(cantidad: float) -> void:
	if health_component:
		print("--------------------------------------------------")
		print("❤️ [DEBUG PLAYER] ¡Corazón recogido!")
		print("   -> Vida Máxima ANTES: ", health_component.maxHealth)
		print("   -> Vida Actual ANTES: ", health_component.currentHealth)
		
		health_component.maxHealth += cantidad
		health_component.currentHealth += cantidad 
		
		print("   -> Vida Máxima AHORA: ", health_component.maxHealth)
		print("   -> Vida Actual AHORA: ", health_component.currentHealth)
		print("--------------------------------------------------")
		
		# 🌟 REPARACIÓN DE LA INTERFAZ: 
		# Forzamos a la UI a enterarse del cambio de salud pasándole el nuevo máximo si vuestra señal lo admite,
		# o si tenéis un nodo "HealthBar" o "VidaBar" en el Player, se actualiza directamente aquí:
		if has_node("MarginContainer/HealthBar"): # <- Ajusta esta ruta a tu nodo de barra de vida
			var hb = get_node("MarginContainer/HealthBar")
			hb.max_value = health_component.maxHealth
			hb.value = health_component.currentHealth
		
		# Emitimos la señal por si la barra lee desde fuera
		if health_component.has_signal("onHealthChanged"):
			health_component.onHealthChanged.emit(health_component.currentHealth)

func curar_vida(cantidad: float) -> void:
	if health_component:
		health_component.currentHealth = min(health_component.maxHealth, health_component.currentHealth + cantidad)
		
		if health_component.has_signal("onHealthChanged"):
			health_component.onHealthChanged.emit(health_component.currentHealth)
		print("❤️ ¡Jugador curado! Vida actual: ", health_component.currentHealth)

func aumentar_daño_base(cantidad: int) -> void:
	bonus_daño += cantidad
	print("⚔️ ¡Daño base aumentado! Bonus acumulado: +", bonus_daño)

func _on_player_muerto() -> void:
	print("💀 [Player] ¡Muerte detectada! Lanzando Game Over de forma externa e independiente...")
	
	# 🌟 TRUCO MAESTRO: Instanciamos la pantalla de muerte
	var pantalla_muerte = GAME_OVER_SCENE.instantiate()
	
	# En vez de añadirlo al 'current_scene' (donde está el player que va a morir),
	# lo añadimos a la raíz absoluta del motor (el Root Viewport).
	# Así, nada del mapa puede destruirla ni interferir con ella.
	get_tree().root.add_child(pantalla_muerte)
	
	print("🖥️ [Player] ¡Pantalla de Game Over blindada en la raíz del motor!")
