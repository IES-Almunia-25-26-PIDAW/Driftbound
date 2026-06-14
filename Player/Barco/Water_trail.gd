extends Line2D

@export var target_node: Node2D
@export var max_points: int = 20
@export var min_spawn_distances: float = 2.0
@export var fade_speed: float = 0.05
@export var base_width: float = 34.0

var time_since_last_fade: float = 0.0

func _ready() -> void:
	set_as_top_level(true)
	clear_points()

func _process(delta):
	if not target_node:
		return
	
	var current_pos = target_node.global_position
	var local_pos = to_local(current_pos)
	
	if points.size() == 0 or local_pos.distance_to(points[-1]) > min_spawn_distances:
		add_point(local_pos)
	
	if points.size() > max_points:
		remove_point(0)
	
	time_since_last_fade += delta
	if time_since_last_fade >= fade_speed:
		if points.size() > 0:
			remove_point(0)
		time_since_last_fade = 0.0
		
	update_trail_visuals()

func update_trail_visuals():
	if points.size() < 2:
		width = lerp(width, 0.0, 0.2)
		return

	var percentage = float(points.size()) / float(max_points)
	
	var target_w = base_width * percentage
	
	width = lerp(width, target_w, 0.1)
