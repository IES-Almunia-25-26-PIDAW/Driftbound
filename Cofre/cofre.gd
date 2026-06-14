extends StaticBody2D
class_name Cofre

# 🌟 Ruta a la escena .tscn del ítem
const ITEM_SCENE = preload("res://Player/Items/item_recogible.tscn") 

@export var vida_cofre: int = 1
var roto: bool = false

func _ready() -> void:
	# Lo registramos en su propio grupo para tenerlo organizado
	add_to_group("cofres_normales")
	
	# Conectamos las señales físicas por si acaso, pero el proyectil
	# ahora se encargará de avisar directamente mediante su función dedicada.
	if has_node("DetectorProyectiles"):
		var detector = $DetectorProyectiles
		if not detector.area_entered.is_connected(_on_algo_entro_area):
			detector.area_entered.connect(_on_algo_entro_area)

func _on_algo_entro_area(area: Area2D) -> void:
	if roto: return
	
	# Si el objeto que entra es un Proyectil oficial (comprobamos por clase o grupo)
	if area is Proyectil or area.is_in_group("proyectiles"):
		recibir_disparo_cofre()

# 🌟 ESTA ES LA FUNCIÓN CLAVE QUE LLAMA TU PROYECTIL NUEVO
# Funciona siempre: da igual si es el primer tiro, el segundo o el número cien.
func recibir_disparo_cofre() -> void:
	if roto: return
	
	print("🔓 [Cofre Normal] ¡Impacto certero detectado desde el Proyectil!")
	recibir_daño(1)

func recibir_daño(cantidad: int) -> void:
	if roto: return
	vida_cofre -= cantidad
	if vida_cofre <= 0:
		romper_cofre()

func romper_cofre() -> void:
	if roto: return
	roto = true
	
	print("🎁 [Cofre Normal] Rompiendo cofre y generando recompensa...")
	
	var opciones = ["vida_max", "curacion", "daño"]
	var elegido = opciones[randi() % opciones.size()]
	
	var nuevo_item = ITEM_SCENE.instantiate() as ItemRecogible
	nuevo_item.tipo_objeto = elegido
	
	match elegido:
		"daño": nuevo_item.valor_efecto = 3.0
		"vida_max": nuevo_item.valor_efecto = 20.0
		"curacion": nuevo_item.valor_efecto = 25.0
	
	nuevo_item.global_position = global_position
	get_tree().current_scene.add_child(nuevo_item)
	
	# Nos eliminamos de la escena de forma limpia
	queue_free()
