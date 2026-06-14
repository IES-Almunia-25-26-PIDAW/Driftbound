extends CharacterBody2D

@export var speed := 250
@onready var sprite_ripple = $Circle
var dir = Vector2.ZERO
var frame_index = 1
func _physics_process(delta):
	dir = Vector2.ZERO
	
	if Input.is_action_pressed("d_move"):
		dir.x += 1
	elif Input.is_action_pressed("a_move"):
		dir.x -= 1
	elif Input.is_action_pressed("w_move"):
		dir.y -= 1
	elif Input.is_action_pressed("s_move"):
		dir.y += 1
	
	velocity = dir.normalized() * speed
	move_and_slide()
	
	# Cambio de Sprite dependiendo de la dirección
	if velocity != Vector2.ZERO:
		frame_index = get_frame_from_vector(velocity)
		$Sprite.frame = frame_index
		sprite_ripple.rotation = velocity.angle();
	else: 
		$Sprite.frame = frame_index

func get_frame_from_vector(dir: Vector2) -> int:
	var angle = dir.angle()
	var deg = fmod(rad_to_deg(angle) + 360.0 , 360.0)
	
	if deg >= 315 or deg < 45:
		return 3 # Derecha
	elif deg < 135:
		return 1 # Abajo
	elif deg < 225:
		return 7 # Arriba
	else:
		return 5 # Izquierda
		
		
