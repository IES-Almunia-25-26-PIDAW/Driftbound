extends CharacterBody2D
class_name CofreMimic

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_activacion: Area2D = $AreaActivacion
@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar = $HealthBar
@onready var sensor: Sensor = $Sensor
@onready var movement: Movement = $Movement

const ITEM_SCENE = preload("res://Player/Items/item_recogible.tscn") 
const SPRITESHEET_MIMIC = preload("res://assets/sprites/Cofre-Mimic.png") 

@export var daño_contacto: float = 2.0
@export var velocidad_original: float = 85.0

var velocidad_actual: float = 85.0
var despierto: bool = false
var jugador_objetivo: Node2D = null
var muerto: bool = false
var esta_frenado_por_ataque: bool = false

var esta_quemado: bool = false
var tiempo_fuego: float = 0.0
var daño_fuego_por_segundo: int = 1

func _ready() -> void:
	if movement and movement.has_method("setup"):
		movement.setup(self)
	
	if sprite_2d:
		sprite_2d.texture = SPRITESHEET_MIMIC
		sprite_2d.hframes = 2  
		sprite_2d.vframes = 1
		sprite_2d.frame = 0 
	
	if health_bar:
		health_bar.visible = false
	
	if area_activacion:
		area_activacion.body_entered.connect(_on_jugador_detectado)
	
	if health_component:
		if health_component.has_signal("onHealthChanged"):
			health_component.onHealthChanged.connect(_on_mimic_recibio_daño)

func _on_jugador_detectado(body: Node) -> void:
	if body.is_in_group("grupo_jugador") and not despierto:
		despertar(body)

func _on_mimic_recibio_daño() -> void:
	if sprite_2d and not muerto:
		sprite_2d.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.15).timeout
	actualizar_color_estado()

func despertar(target: Node2D) -> void:
	despierto = true
	jugador_objetivo = target
	if sprite_2d:
		sprite_2d.frame = 1 
	if health_bar:
		health_bar.visible = true
	print("👹 ¡El Mímico ha despertado!")

func _physics_process(delta: float) -> void:
	if not despierto or muerto or esta_frenado_por_ataque:
		if movement and movement.has_method("move"):
			movement.move(Vector2.ZERO)
		return

	if jugador_objetivo and movement and movement.has_method("move"):
		movement.speed = velocidad_actual
		var direccion = global_position.direction_to(jugador_objetivo.global_position)
		movement.move(direccion)
		
		for i in get_slide_collision_count():
			var colision = get_slide_collision(i)
			var objeto = colision.get_collider()
			if objeto.is_in_group("grupo_jugador"):
				atacar_jugador(objeto)

func atacar_jugador(jugador: Node) -> void:
	if esta_frenado_por_ataque or muerto: return
	
	if jugador.has_node("HealthComponent"):
		var hc = jugador.get_node("HealthComponent")
		if hc.has_method("recibir_daño"):
			hc.recibir_daño(daño_contacto)
		elif hc.has_method("takeDamage"):
			hc.takeDamage(daño_contacto)
			
		if jugador.has_method("recibir_golpe_efecto"):
			jugador.recibir_golpe_efecto()
			
		esta_frenado_por_ataque = true
		await get_tree().create_timer(0.5).timeout
		esta_frenado_por_ataque = false

func recibir_efecto_elemental(tipo_elemento: String, dir_impacto: Vector2, daño_base: int) -> void:
	if muerto: return
	
	if not despierto:
		var jugadores = get_tree().get_nodes_in_group("grupo_jugador")
		if jugadores.size() > 0: despertar(jugadores[0])

	if health_component and health_component.has_method("takeDamage"):
		health_component.takeDamage(daño_base)
	
	# 🌟 COMPROBACIÓN FULMINANTE: Si el golpe lo mata, soltamos el botín ya mismo
	if health_component and ("currentHealth" in health_component and health_component.currentHealth <= 0) or ("health" in health_component and health_component.health <= 0):
		_on_mimic_muerto()
		return

	match tipo_elemento:
		"Fuego":
			if not esta_quemado and randf() <= 0.5:
				esta_quemado = true
				actualizar_color_estado()
				for i in range(5):
					await get_tree().create_timer(1.0).timeout
					if not esta_quemado or muerto: break
					if health_component and health_component.has_method("takeDamage"):
						health_component.takeDamage(daño_fuego_por_segundo)
						if health_component.currentHealth <= 0:
							_on_mimic_muerto()
							break
						if sprite_2d: sprite_2d.modulate = Color(1, 0.4, 0.2)
						await get_tree().create_timer(0.1).timeout
						actualizar_color_estado()
				if esta_quemado and not muerto: apagar_fuego()

		"Agua":
			if esta_quemado:
				apagar_fuego()
			else:
				velocidad_actual = velocidad_original * 0.5
				actualizar_color_estado()
				await get_tree().create_timer(3.0).timeout
				if not esta_quemado and not muerto:
					velocidad_actual = velocidad_original
					actualizar_color_estado()

		"Tierra":
			var fuerza_empuje = 500.0
			velocity = dir_impacto * fuerza_empuje
			move_and_slide()
			await get_tree().create_timer(0.15).timeout
			velocity = Vector2.ZERO

func apagar_fuego() -> void:
	esta_quemado = false
	tiempo_fuego = 0.0
	actualizar_color_estado()

func actualizar_color_estado() -> void:
	if muerto: return
	if sprite_2d: sprite_2d.modulate = Color(1, 1, 1, 1)
	if esta_quemado: modulate = Color(1, 0.6, 0)
	elif velocidad_actual < velocidad_original: modulate = Color(0.4, 0.7, 1)
	else: modulate = Color(1, 1, 1, 1)

func _on_mimic_muerto() -> void:
	if muerto: return
	muerto = true
	print("💀 [MÍMICO] ¡Muerte detectada! Instanciando recompensa...")
	
	var opciones = ["vida_max", "curacion", "daño"]
	var elegido = opciones[randi() % opciones.size()]
	
	var nuevo_item = ITEM_SCENE.instantiate() as ItemRecogible
	nuevo_item.tipo_objeto = elegido
	
	match elegido:
		"daño": nuevo_item.valor_efecto = 3.0
		"vida_max": nuevo_item.valor_efecto = 2.0
		"curacion": nuevo_item.valor_efecto = 3.0
		
	nuevo_item.global_position = global_position
	get_tree().current_scene.add_child(nuevo_item)
	print("🎁 [MÍMICO EXITO] El botín de tipo [", elegido, "] ha sido arrojado al suelo.")
	
	if health_bar: health_bar.visible = false
	collision_layer = 0
	collision_mask = 0
