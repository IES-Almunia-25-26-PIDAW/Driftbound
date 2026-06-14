extends CharacterBody2D
class_name Enemy

@onready var movement: Movement = $"Movement" as Movement
@onready var sensor: Sensor = $"Sensor" as Sensor
@onready var sprite: Sprite2D = $Sprite2D # Obtenemos la referencia a tu nodo Sprite2D

# Buscamos el componente de salud que está dentro del enemigo
@onready var health_component: HealthComponent = $HealthComponent 

# --- VARIABLES PARA EL KNOCKBACK ---
@export var knockback_force: float = 200.0  
var is_getting_knockback: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

var player: CollisionObject2D
var input_vector: Vector2
var frame_index = 1
var is_frozen: bool = false

# --- Variables de Estados Elementales ---
var esta_quemado: bool = false
var tiempo_fuego: float = 0.0
var daño_fuego_por_segundo: int = 1 # Usamos un entero limpio para el HealthComponent

# Ajusta estas velocidades a las que use tu enemigo normalmente
var velocidad_original: float = 90.0
var velocidad_actual: float = 90.0

func _ready():
	movement.setup(self)
	
	# Si existe el componente de salud, nos conectamos a su señal de recibir daño
	if health_component:
		health_component.onDamageTook.connect(_on_enemy_took_damage)
	
func _physics_process(delta):
	if is_frozen:
		velocity = Vector2.ZERO
		move_and_slide() 
		return 
		
	if is_getting_knockback:
		velocity = knockback_velocity
		move_and_slide()
		return 
		
	if sensor.target != null:
		if sensor.targetDistance > 10: 
			# 🌟 Ajustamos la velocidad actual (por si está ralentizado por agua)
			movement.speed = velocidad_actual
			movement.move(sensor.targetDirection)
			
	if velocity != Vector2.ZERO:
		frame_index = get_frame_from_vector(velocity)
		sprite.frame = frame_index
	else: 
		sprite.frame = frame_index

# 🌟 Modificado: Ahora recibe el daño_base que viene del impacto del proyectil
func recibir_efecto_elemental(tipo_elemento: String, dir_impacto: Vector2, daño_base: int) -> void:
	
	# 💥 1. Aplica el daño del golpe inicial inmediatamente
	if health_component:
		health_component.takeDamage(daño_base)
		print("💥 Impacto inicial de ", tipo_elemento, ". Daño: ", daño_base)
		
	# 🌀 2. Procesa las reacciones elementales
	match tipo_elemento:
		"Fuego":
			# 50% de probabilidad
			if not esta_quemado and randf() <= 0.5:
				esta_quemado = true
				modulate = Color(1, 0.6, 0) # Se tiñe de color fuego
				print("🔥 ¡Enemigo quemado! Iniciando tics de daño.")
				
				# 🌟 Bucle seguro de 5 segundos (1 tic de daño por segundo exacto)
				for i in range(5):
					await get_tree().create_timer(1.0).timeout
					
					# Si un proyectil de agua nos apaga en mitad del bucle, frena
					if not esta_quemado: 
						break
						
					if health_component:
						health_component.takeDamage(daño_fuego_por_segundo)
						print("🔥 Daño de quemadura. Vida restada: ", daño_fuego_por_segundo)
						
						# Pequeño parpadeo de fuego
						modulate = Color(1, 0.4, 0.2)
						await get_tree().create_timer(0.1).timeout
						if esta_quemado: modulate = Color(1, 0.6, 0)
						
				# Si completó los 5 segundos sin que lo apaguen, se extingue solo
				if esta_quemado:
					apagar_fuego()
			else:
				if not esta_quemado:
					print("💨 El fuego golpeó, pero no logró quemar (50% fallado).")

		"Agua":
			# 🌟 INTERACCIÓN: Si estaba quemado, el agua lo apaga
			if esta_quemado:
				apagar_fuego()
				print("💧💨 ¡El agua ha evaporado y apagado el fuego!")
			else:
				# Si no estaba quemado, lo ralentiza al 50%
				velocidad_actual = velocidad_original * 0.5
				modulate = Color(0.4, 0.7, 1) # Se vuelve azulado
				print("💧 ¡Enemigo empapado y ralentizado por 3 segundos!")
				
				# Esperamos 3 segundos y restauramos velocidad
				await get_tree().create_timer(3.0).timeout
				if not esta_quemado: 
					velocidad_actual = velocidad_original
					modulate = Color(1, 1, 1) 

		"Tierra":
			print("🪨 ¡Impacto de Tierra! Empujón hacia atrás (Knockback).")
			var fuerza_empuje = 500.0
			velocity = dir_impacto * fuerza_empuje
			move_and_slide()
			
			await get_tree().create_timer(0.15).timeout
			velocity = Vector2.ZERO

# Función auxiliar para limpiar el estado de fuego
func apagar_fuego() -> void:
	esta_quemado = false
	tiempo_fuego = 0.0
	modulate = Color(1, 1, 1) # Recupera su color original
	print("🛑 El fuego se ha extinguido.")

func get_frame_from_vector(dir: Vector2) -> int:
	var angle = dir.angle()
	var deg = fmod(rad_to_deg(angle) + 360.0 , 360.0)
	
	if deg >= 315 or deg < 45:
		return 2 # Derecha
	elif deg < 135:
		return 0 # Abajo
	elif deg < 225:
		return 3 # Arriba
	else:
		return 1 # Izquierda

func recibir_knockback():
	if sensor.target != null:
		var direccion_empujon = -sensor.targetDirection.normalized()
		knockback_velocity = direccion_empujon * knockback_force
		is_getting_knockback = true
		
		await get_tree().create_timer(0.15).timeout
		
		is_getting_knockback = false
		knockback_velocity = Vector2.ZERO

func _on_enemy_took_damage():
	sprite.modulate = Color(1, 0, 0, 1) # Se pone rojo
	await get_tree().create_timer(0.15).timeout
	
	# Al recuperar el color, mantiene el tinte de su estado actual
	if esta_quemado:
		modulate = Color(1, 0.6, 0)
	elif velocidad_actual < velocidad_original:
		modulate = Color(0.4, 0.7, 1)
	else:
		sprite.modulate = Color(1, 1, 1, 1)
		modulate = Color(1, 1, 1, 1)

func congelar_por_ataque():
	if is_frozen: return 
	is_frozen = true
	await get_tree().create_timer(1).timeout
	is_frozen = false
