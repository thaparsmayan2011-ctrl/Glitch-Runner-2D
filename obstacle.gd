extends Area2D

const NORMAL_SPRITES = [
	preload("res://sprites/obstaclesmall.png"),
	preload("res://sprites/obstaclemedium.png"),
	preload("res://sprites/mediumobstacleglitc.png")
]

const CORRUPTED_SPRITE=preload("res://sprites/tallcorrupted.png")


var scrollv=300
var base_scrollv =300
var corrupted = false
var passed = false
var ceiling_mode = false
var height =60

func _ready():
	body_entered.connect(_on_body_entered)
	$CollisionShape2D.shape= $CollisionShape2D.shape.duplicate()
	var h = 200 if corrupted else height
	if corrupted:
		$Sprite2D.texture = CORRUPTED_SPRITE
	else:
		$Sprite2D.texture = NORMAL_SPRITES[randi()% NORMAL_SPRITES.size()]
	var tex_size= $Sprite2D.texture.get_size()
	var scale_factor = h/ tex_size.y
	$Sprite2D.scale =Vector2(scale_factor, scale_factor)
	var w =tex_size.x * scale_factor
	$CollisionShape2D.shape.size =Vector2(w,h)
			
	if ceiling_mode:
		$Sprite2D.flip_v = true
		$CollisionShape2D.position= Vector2(0,-30+ h/2.0)
		$Sprite2D.position = Vector2(0, -30 + h/2.0)
	else:
		$CollisionShape2D.position = Vector2(0, 30-h/2)
		$Sprite2D.position = Vector2(0, 30- h/2.0)
	
	if corrupted:
		$Sprite2D.modulate.a= 0
		var tween= create_tween()
		tween.tween_property($Sprite2D, "modulate:a", 1, 0.4)
			
		
func _physics_process(delta):
	if get_tree().current_scene.gameover_state or get_tree().current_scene.user_paused:
		return
	var	current_scene = get_tree().current_scene
	scrollv = base_scrollv* current_scene.glitch_speed_multiplier
	position.x -= scrollv*delta
	if not passed and position.x < 200:
		passed = true
		get_tree().current_scene.obstacle_cleared(get_tree().current_scene.glitch_active)	
	if position.x< -700:
		queue_free()
		
func _on_body_entered(body):
	if body.name !="player":
		return
	var current_scene = get_tree().current_scene
	if current_scene.gameover_state:
		return
	if current_scene.glitch_active:
		return
	
	print("Player HIT- Game Over")
	current_scene.game_over()	
			
		
		
		
		
		
		
		
			
	 	
