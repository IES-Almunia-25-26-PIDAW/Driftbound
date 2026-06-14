extends Node
@onready var mar_material = $CanvasLayer/Mar/Parallax2D/ColorRect2.material
@onready var barco = $Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var pos = barco.global_position
	mar_material.set_shader_parametrer("world_pos", pos)
