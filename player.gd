extends CharacterBody2D

const SPEED=300
const JUMPV= -530
const GRAVITY = 1200
const SCROLLV =200

const BOY_NORMAL =preload("res://sprites/boynormal.png")


const BOY_GLITCH =preload("res://sprites/boyglitch.png")


const GIRL_NORMAL = preload("res://sprites/girlnormal.png")


const GIRL_GLITCH = preload("res://sprites/girlglitch.png")


const ROCKET_NORMAL= preload("res://sprites/rocketmain.png")


const ROCKET_GLITCH = preload("res://sprites/rocketglitch.png")


var glitch_visual_time = 0
var gravity_visual_time =0
var was_grounded = true
var current_character = "boy"

func _physics_process(delta):
	var current_scene = get_tree().current_scene
	if current_scene.glitch_active:
		glitch_visual_time += delta
		
	if current_scene.gameover_state or current_scene.user_paused:
		velocity = Vector2.ZERO
		return
		
		
	floor_snap_length =1
	if current_scene.gravity_flip_active:
		$Sprite2D.position.y = 6
	else: 
		$Sprite2D.position.y = -6	
	
	
	var g_sign = -1 if current_scene.gravity_flip_active else 1
	var grounded = is_on_floor()
	
	if current_scene.gravity_flip_active:
		grounded = is_on_ceiling()
	if grounded and not was_grounded:
		landing_bump()
	was_grounded = grounded		
	if not grounded:
		velocity.y += GRAVITY*delta*g_sign
	if Input.is_action_just_pressed("ui_accept") and grounded:
		velocity.y = JUMPV*g_sign
		current_scene.play_jump_sfx()
	velocity.x = 0
		
	move_and_slide()
	
func set_glitch_visual(active):
	var normal_tex = BOY_NORMAL
	var glitch_tex = BOY_GLITCH
	if current_character == "girl":
		normal_tex = GIRL_NORMAL
		glitch_tex = GIRL_GLITCH
	elif current_character == "rocket":
		normal_tex = ROCKET_NORMAL
		glitch_tex = ROCKET_GLITCH
		
	if active:
		if int(glitch_visual_time*10)% 2== 0:
			$Sprite2D.texture = glitch_tex
		else:
			$Sprite2D.texture = normal_tex
	else:	
		$Sprite2D.texture = normal_tex
	

func shake_camera():
	var cam = $Camera2D
	var original= cam.position
	for i in range(6):
		cam.position= original+ Vector2(randf_range(-6, 6), randf_range(-6, 6))
		await get_tree().create_timer(0.03).timeout
		cam.position = original
func set_gravity_visual(active):
	if active:
		modulate = Color(0.4,0.6,1, modulate.a)
		$Sprite2D.flip_v = true
	
	else:
		modulate = Color(1,1,1, modulate.a)
		$Sprite2D.flip_v = false	
	

	
	
func landing_bump():
	var cam = $Camera2D
	var original = cam.position
	cam.position = original +Vector2(0, 4)
	await get_tree().create_timer(0.05).timeout
	cam.position=original
	
func set_character(character_name):
	current_character= character_name
	var normal_tex = BOY_NORMAL
	if character_name== "girl":
		normal_tex = GIRL_NORMAL
	elif character_name== "rocket":
		normal_tex = ROCKET_NORMAL
	$Sprite2D.texture= normal_tex 		
	
		
