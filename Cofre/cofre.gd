extends StaticBody2D
class_name Cofre

# 🌟 Asegúrate de que esta ruta apunte a tu escena .tscn del ítem
const ITEM_SCENE = preload("res://Player/Items/item_recogible.tscn") 

@export var vida_cofre: int = 1
var roto: bool = false

func _ready() -> void:
	add_to_group("enemigos")
	
	# Conectamos el detector de forma segura
	if has_node("DetectorProyectiles"):
		var detector = $DetectorProyectiles
		detector.area_entered.connect(_on_algo_entro_area)
		detector.body_entered.connect(_on_algo_entro_cuerpo)

func _on_algo_entro_area(area: Area2D) -> void:
	# Ignoramos si es el propio jugador o el mapa
	if area.is_in_group("grupo_jugador") or area.name == "AreaIman": return
	
	# Si es un proyectil válido, procesamos el impacto
	var nombre = area.name.to_lower()
	if "proyectil" in nombre or "ball" in nombre or "ataque" in nombre or area.is_in_group("enemigos"):
		procesar_impacto_recogido(area)

func _on_algo_entro_cuerpo(body: Node) -> void:
	if body == self or body.is_in_group("grupo_jugador"): return
	
	var nombre = body.name.to_lower()
	if "proyectil" in nombre or "ball" in nombre:
		procesar_impacto_recogido(body)

func procesar_impacto_recogido(objeto: Node) -> void:
	if roto: return
	
	# Borramos el proyectil para que no siga de largo
	if objeto.has_method("queue_free"):
		objeto.queue_free()
	elif objeto.get_parent().has_method("queue_free") and objeto.get_parent() != self:
		objeto.get_parent().queue_free()

	recibir_daño(1)

func recibir_daño(cantidad: int) -> void:
	if roto: return
	vida_cofre -= cantidad
	if vida_cofre <= 0:
		romper_cofre()

func romper_cofre() -> void:
	roto = true
	
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
	queue_free()
