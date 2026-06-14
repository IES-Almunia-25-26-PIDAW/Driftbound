extends Sprite2D

@export var Boat: Node2D

func _process(_delta):
	if Boat:
		global_position = Boat.global_position
		if Boat is CharacterBody2D and Boat.velocity.length() > 0:
			rotation = Boat.velocity.angle()
