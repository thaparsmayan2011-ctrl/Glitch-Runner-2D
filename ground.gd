extends StaticBody2D

const SCROLLV= 300

@export var other_ground_path: NodePath

func _physics_process(delta):
	if get_tree().current_scene.gameover_state or get_tree().current_scene.user_paused:
		return
		
	var current_scene = get_tree().current_scene
	var ground_speed = min(550, 300 + current_scene.timeS * 4)* current_scene.speed_multiplier* current_scene.glitch_speed_multiplier
	position.x -= ground_speed* delta
	
	
	
	if position.x <= -2390:
		var other = get_node(other_ground_path)
		position.x =other.position.x +2390
		 
	
	
	
