extends Area2D
class_name Sensor

var target: CollisionObject2D
var colisiones = []

var targetDistance : get = _get_distance
var targetDirection :
	get :
		return target.global_position - global_position

func _ready():
	body_entered.connect(store_body)
	body_exited.connect(remove_body)
	
func _get_distance() -> float:
	return global_position.distance_to(target.global_position)
	
func store_body(body):
	colisiones.append(body)
	
func remove_body(body):
	colisiones.erase(body)
	
	if colisiones.size() == 0:
		target = null

func find_closest_body(bodies: Array) -> CollisionObject2D:
	var closestDistance = 1000
	var closestBody = null
	
	if bodies.size() == 0:
		target = null
		return
	
	for body in bodies:
		if body != null:
			var distance  = body.global_position.distance_to(global_position)
			if distance < closestDistance:
				closestDistance = distance
				closestBody = body
				target = closestBody
	return closestBody
	
func scan() -> void:
	if colisiones.size() == 0:
		return
	var closestBody = find_closest_body(colisiones)
	if closestBody != null:
		target = closestBody
	else:
		target = null
func _physics_process(delta):
	scan()
